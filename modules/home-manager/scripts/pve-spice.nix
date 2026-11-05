# pve-spice: open a Proxmox VM's SPICE console in RemoteViewer.
# Usage: pve-spice 106   or   pve-spice myvm
# Everything comes from the flake: `host` is set by the caller, and the API
# token is read from `tokenFile` (a sops-nix secret, content:
# 'user@realm!tokenid=secret', role PVEVMUser on /vms). Nothing lives in ~/.config.
# PVE_HOST in the environment overrides the host for one-off use.
{ pkgs, host, tokenFile }:
pkgs.writeShellApplication {
  name = "pve-spice";
  runtimeInputs = [ pkgs.curl pkgs.jq ];
  text = ''
    [ $# -eq 1 ] || { echo "usage: pve-spice <vmid|name>" >&2; exit 2; }
    PVE_HOST=''${PVE_HOST:-${host}}
    [ -r "${tokenFile}" ] || { echo "token file ${tokenFile} missing or unreadable (sops secret pve_token)" >&2; exit 1; }
    PVE_TOKEN=$(tr -d '[:space:]' < "${tokenFile}")

    api() { curl -sk --fail-with-body -H "Authorization: PVEAPIToken=$PVE_TOKEN" "$@"; }

    res=$(api "https://$PVE_HOST:8006/api2/json/cluster/resources?type=vm") \
      || { echo "API call failed (token/permissions?): $res" >&2; exit 1; }
    ID="" NODE=""
    read -r ID NODE <<<"$(jq -r --arg a "$1" \
      '.data[] | select(.type=="qemu" and (.name==$a or (.vmid|tostring)==$a)) | "\(.vmid) \(.node)"' \
      <<<"$res" | head -1)" || true
    [ -n "$ID" ] || {
      echo "no qemu VM '$1' visible to this token. Visible: $(jq -r '[.data[]|select(.type=="qemu")|"\(.vmid)=\(.name)"]|join(", ")' <<<"$res")" >&2
      exit 1
    }

    # The .vv file holds a ~30 s ticket: keep it in a private temp dir, remove on exit.
    dir=$(mktemp -d -t pvespice.XXXXXX)
    trap 'rm -rf "$dir"' EXIT
    f="$dir/vm.vv"
    api -X POST -d "proxy=$PVE_HOST" \
        "https://$PVE_HOST:8006/api2/json/nodes/$NODE/qemu/$ID/spiceproxy" \
      | jq -r '.data | "[virt-viewer]", (to_entries[] | "\(.key)=\(.value)")' > "$f"

    # The remoteviewer cask installs RemoteViewer.app (no remote-viewer binary).
    # -W waits for the app to quit so the temp file outlives the connection.
    open -W -a RemoteViewer "$f"
  '';
}
