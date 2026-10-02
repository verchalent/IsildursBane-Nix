{ lib, ... }:
let
  # Mounts on demand via autofs (macOS equivalent of x-systemd.automount).
  # Bare "nirankar" resolves via MagicDNS when Tailscale is up, else via LAN DNS (.localdomain).
  # Paths are under /System/Volumes/Data/mnt; /mnt is a synthetic.conf symlink to it.
  nfsOpts = "-fstype=nfs,rw,resvport,nfsvers=3,soft,intr,tcp,nosuid";
  mounts = {
    "/System/Volumes/Data/mnt/Nirankar/Media" = "nirankar:/volume1/Media";
  };
in
{
  environment.etc."auto_nirankar".text = lib.concatStringsSep "\n"
    (lib.mapAttrsToList (path: src: "${path}\t${nfsOpts}\t${src}") mounts) + "\n";

  system.activationScripts.postActivation.text = ''
    # /mnt on the read-only system volume: synthetic.conf symlink -> /System/Volumes/Data/mnt
    mkdir -p /System/Volumes/Data/mnt/Nirankar
    if ! grep -qE '^mnt[[:space:]]' /etc/synthetic.conf 2>/dev/null; then
      echo "adding /mnt to /etc/synthetic.conf..." >&2
      printf 'mnt\tSystem/Volumes/Data/mnt\n' >> /etc/synthetic.conf
    fi
    if [ ! -L /mnt ]; then
      /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t || \
        echo "warning: /mnt symlink not created; reboot to apply synthetic.conf" >&2
    fi

    # macOS owns /etc/auto_master (and may reset it on upgrade), so append rather than replace
    if ! grep -q 'auto_nirankar' /etc/auto_master; then
      echo "adding auto_nirankar to /etc/auto_master..." >&2
      printf '/-\t\t\tauto_nirankar\t-nobrowse\n' >> /etc/auto_master
    fi
    /usr/sbin/automount -c
  '';
}
