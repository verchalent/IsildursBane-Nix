# pve-spice: open a Proxmox VM's SPICE console in remote-viewer.
# Usage: pve-spice 106   or   pve-spice myvm
# Everything comes from the flake: `host` is set by the caller, and the API
# token is read from `tokenFile` (a sops-nix secret, content:
# 'user@realm!tokenid=secret', role PVEVMUser on /vms). Nothing lives in ~/.config.
# PVE_HOST in the environment overrides the host for one-off use.
{ pkgs, host, tokenFile }:
pkgs.writeShellApplication {
  name = "pve-spice";
  runtimeInputs = [ pkgs.jq pkgs.virt-viewer ]; # curl: macOS /usr/bin/curl, see api() below
  text = ''
    [ $# -eq 1 ] || { echo "usage: pve-spice <vmid|name>" >&2; exit 2; }
    PVE_HOST=''${PVE_HOST:-${host}}
    [ -r "${tokenFile}" ] || { echo "token file ${tokenFile} missing or unreadable (sops secret pve_token)" >&2; exit 1; }
    PVE_TOKEN=$(tr -d '[:space:]' < "${tokenFile}")

    # /usr/bin/curl, not nixpkgs curl: it reaches the LAN where the nix-store one gets "could not connect"
    # (macOS local-network privacy applies per binary).
    api() { /usr/bin/curl -sSk --connect-timeout 5 --fail-with-body -H "Authorization: PVEAPIToken=$PVE_TOKEN" "$@"; }

    res=$(api "https://$PVE_HOST:8006/api2/json/cluster/resources?type=vm") \
      || { echo "API call failed (see curl error above; 401/403 = token/permissions): $res" >&2; exit 1; }
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
    # PVE_KEEP=1 keeps the file (it has a ticket: redact password= before sharing it).
    if [ -n "''${PVE_KEEP:-}" ]; then echo "keeping $dir/vm.vv" >&2; else trap 'rm -rf "$dir"' EXIT; fi
    f="$dir/vm.vv"
    # The CA cert value contains real newlines; a .vv file needs them as a literal \n.
    api -X POST -d "proxy=$PVE_HOST" \
        "https://$PVE_HOST:8006/api2/json/nodes/$NODE/qemu/$ID/spiceproxy" \
      | jq -r '.data | "[virt-viewer]", (to_entries[] | "\(.key)=\(.value | tostring | gsub("\n"; "\\n"))")' > "$f"

    # remote-viewer comes from nixpkgs virt-viewer (native arm64; the brew tap's source
    # URL is dead and the remoteviewer cask is x86_64-only). It blocks until the console
    # closes, so the temp file outlives the connection.
    remote-viewer "$f"
  '';
}
