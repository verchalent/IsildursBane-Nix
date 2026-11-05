# pve-spice: open a Proxmox VM's SPICE console in remote-viewer.
# Usage: pve-spice 106   or   pve-spice myvm
# Everything comes from the flake: the API token is read from `tokenFile` (a sops-nix
# secret, content: 'user@realm!tokenid=secret', role PVEVMUser on /vms). The SSH
# destination for the SPICE tunnel is read from `sshTargetFile` (a sops-nix secret,
# content: 'user@host'), and its host part is also the API host.
# Nothing lives in ~/.config.
# PVE_HOST and PVE_SSH in the environment override these for one-off use.
{ pkgs, tokenFile, sshTargetFile }:
pkgs.writeShellApplication {
  name = "pve-spice";
  runtimeInputs = [ pkgs.jq pkgs.virt-viewer ]; # curl: macOS /usr/bin/curl, see api() below
  text = ''
    [ $# -eq 1 ] || { echo "usage: pve-spice <vmid|name>" >&2; exit 2; }
    [ -r "${tokenFile}" ] || { echo "token file ${tokenFile} missing or unreadable (sops secret pve_token)" >&2; exit 1; }
    PVE_TOKEN=$(tr -d '[:space:]' < "${tokenFile}")
    if [ -z "''${PVE_SSH:-}" ]; then
      [ -r "${sshTargetFile}" ] || { echo "ssh target file ${sshTargetFile} missing or unreadable (sops secret pve_ssh_target)" >&2; exit 1; }
      PVE_SSH=$(tr -d '[:space:]' < "${sshTargetFile}")
    fi
    PVE_HOST=''${PVE_HOST:-''${PVE_SSH#*@}}

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
    sock="$dir/ssh.sock"
    # PVE_KEEP=1 keeps the file (it has a ticket: redact password= before sharing it).
    # The tunnel always closes.
    [ -z "''${PVE_KEEP:-}" ] || echo "keeping $dir/vm.vv" >&2
    trap '/usr/bin/ssh -S "$sock" -O exit "$PVE_SSH" 2>/dev/null || true; [ -n "''${PVE_KEEP:-}" ] || rm -rf "$dir"' EXIT
    f="$dir/vm.vv"

    # remote-viewer is a nix-store binary, so macOS local-network privacy blocks it from
    # the LAN ("No route to host"). Reach the SPICE proxy through /usr/bin/ssh on loopback.
    # Opened before the ticket is requested so an SSH prompt can't outlast the ticket.
    port=$((20000 + RANDOM % 20000))
    /usr/bin/ssh -f -N -M -S "$sock" -o ConnectTimeout=5 -o ExitOnForwardFailure=yes \
      -L "127.0.0.1:$port:localhost:3128" "$PVE_SSH" \
      || { echo "SSH tunnel to $PVE_SSH failed (see ssh error above)" >&2; exit 1; }

    # The CA cert value contains real newlines; a .vv file needs them as a literal \n.
    api -X POST -d "proxy=$PVE_HOST" \
        "https://$PVE_HOST:8006/api2/json/nodes/$NODE/qemu/$ID/spiceproxy" \
      | jq -r --arg port "$port" '.data | .proxy = "http://127.0.0.1:\($port)"
          | "[virt-viewer]", (to_entries[] | "\(.key)=\(.value | tostring | gsub("\n"; "\\n"))")' > "$f"

    # remote-viewer comes from nixpkgs virt-viewer (native arm64; the brew tap's source
    # URL is dead and the remoteviewer cask is x86_64-only). It blocks until the console
    # closes, so the temp file outlives the connection.
    remote-viewer "$f"
  '';
}
