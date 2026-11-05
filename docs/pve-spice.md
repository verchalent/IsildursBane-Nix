# pve-spice (toyotama)

Opens a Proxmox VM's SPICE console: `pve-spice <vmid|name>`.
Source: `modules/home-manager/scripts/pve-spice.nix`, installed from `modules/home-manager/toyotama/default.nix`.

## Setup
Two sops secrets in `secrets/toyotama.yaml` (edit with `sops secrets/toyotama.yaml`):
- `pve_token`: `'user@realm!tokenid=secret'`, role `PVEVMUser` on `/vms`.
- `pve_ssh_target`: `'user@host'` of the Proxmox node (its host part is also the API host).

SSH to that node must work non-interactively (key or agent).

## How it works
1. Asks the Proxmox API (macOS `/usr/bin/curl`) for the VM and a SPICE ticket.
2. Opens an SSH tunnel to the node's SPICE proxy (port 3128) and points the `.vv` file at it.
   Why: `remote-viewer` is a nix-store binary and macOS local-network privacy blocks it from the LAN.
3. Runs `remote-viewer`, then closes the tunnel and deletes the temp `.vv`.

## Troubleshooting
- Debug: `PVE_KEEP=1 G_MESSAGES_DEBUG=all pve-spice 100` keeps the `.vv` (contains a short-lived ticket; redact `password=`/`ticket=` before sharing).
- **Connects but shows no output / black screen:** the guest's screen has gone to sleep and SPICE does not wake it.
  Disable screen blanking/screen-off in the guest OS (power settings, or DPMS/screensaver on Linux guests).
- The `hicolor` icon warning from `remote-viewer` is harmless.
- `PVE_HOST` and `PVE_SSH` in the environment override the values from sops for one-off use.
