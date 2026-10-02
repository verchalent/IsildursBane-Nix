{ config, lib, pkgs, ... }:
let
  # SMB mounts of the NAS, done as the primary user by a launchd agent.
  # Mounting as the user (not root via autofs) makes every file appear owned by that user,
  # sidestepping the local(501)/remote(1000) uid mismatch that NFS AUTH_SYS can't remap.
  # NAS host, login, and password come from sops (secrets/toyotama.yaml) to keep them out of the repo.
  # Paths are under /System/Volumes/Data/mnt; /mnt is a synthetic.conf symlink to it.
  user = config.system.primaryUser;
  smbOpts = "nobrowse,soft";
  mountRoot = "/System/Volumes/Data/mnt/Nirankar";
  mounts = {
    "${mountRoot}/Media" = "Media";
    "${mountRoot}/homes" = "homes";
  };
  secretNames = [ "nas_smb_host" "nas_smb_user" "nas_smb_password" ];
  secretPath = name: config.sops.secrets.${name}.path;

  mountScript = pkgs.writeShellScript "mount-nas" ''
    set -u
    # URL-encode so special characters survive the smb:// URL
    read_secret() { ${pkgs.jq}/bin/jq -rn --rawfile v "$1" '$v | rtrimstr("\n") | @uri'; }
    host=$(read_secret ${secretPath "nas_smb_host"}) || exit 1
    user=$(read_secret ${secretPath "nas_smb_user"}) || exit 1
    pw=$(read_secret ${secretPath "nas_smb_password"}) || exit 1

    is_mounted() { /sbin/mount | grep -qF " on $1 (smbfs"; }

    # A mount whose server address went away (e.g. LAN -> Tailscale) hangs instead of erroring.
    # Probe in the background so a hung listing can't block this script; never wait on it.
    is_alive() {
      /bin/ls -a "$1" >/dev/null 2>&1 &
      local pid=$! i
      for i in 1 2 3 4 5 6 7 8 9 10; do
        kill -0 "$pid" 2>/dev/null || { wait "$pid"; return; }
        sleep 0.5
      done
      return 1
    }

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (path: src: ''
      if is_mounted "${path}" && ! is_alive "${path}"; then
        echo "$(date) ${path} unresponsive; force unmounting" >&2
        /sbin/umount -f "${path}" || /usr/sbin/diskutil unmount force "${path}" >/dev/null
      fi
      if ! is_mounted "${path}"; then
        /sbin/mount -t smbfs -o ${smbOpts} "//$user:$pw@$host/${src}" "${path}" \
          && echo "$(date) mounted ${path}" \
          || echo "$(date) failed to mount ${path}" >&2
      fi
    '') mounts)}
  '';
in
{
  sops.secrets = lib.genAttrs secretNames (_: { owner = user; });

  # RunAtLoad covers login; StartInterval retries after sleep/network changes drop a mount.
  launchd.user.agents.mount-nas.serviceConfig = {
    ProgramArguments = [ "${mountScript}" ];
    RunAtLoad = true;
    StartInterval = 60;
    StandardOutPath = "/Users/${user}/Library/Logs/mount-nas.log";
    StandardErrorPath = "/Users/${user}/Library/Logs/mount-nas.log";
  };

  system.activationScripts.postActivation.text = ''
    # /mnt on the read-only system volume: synthetic.conf symlink -> /System/Volumes/Data/mnt
    mkdir -p ${mountRoot}
    if ! grep -qE '^mnt[[:space:]]' /etc/synthetic.conf 2>/dev/null; then
      echo "adding /mnt to /etc/synthetic.conf..." >&2
      printf 'mnt\tSystem/Volumes/Data/mnt\n' >> /etc/synthetic.conf
    fi
    if [ ! -L /mnt ]; then
      /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t || \
        echo "warning: /mnt symlink not created; reboot to apply synthetic.conf" >&2
    fi

    # Drop the old NFS autofs map; its triggers would otherwise sit on the mount points
    if grep -q 'auto_nirankar' /etc/auto_master; then
      echo "removing auto_nirankar from /etc/auto_master..." >&2
      sed -i "" '/auto_nirankar/d' /etc/auto_master
      /usr/sbin/automount -cv >/dev/null
    fi

    # Non-root SMB mounts need user-owned mount points.
    # Clear leftover NFS mounts / autofs triggers first (innermost first, so repeat).
    ${lib.concatMapStringsSep "\n" (path: ''
      for _ in 1 2 3; do
        /sbin/mount | grep -qE " on ${path} \((nfs|autofs)" || break
        /sbin/umount -f "${path}" || break
      done
      if ! /sbin/mount | grep -qF " on ${path} "; then
        mkdir -p "${path}" && chown ${user}:staff "${path}"
      fi
    '') (lib.attrNames mounts)}
  '';
}
