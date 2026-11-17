{ pkgs }:
pkgs.writeScriptBin "nixriot-install" ''
  #!${pkgs.runtimeShell}
  set -euo pipefail

  export PATH=${pkgs.lib.makeBinPath [
      pkgs.gptfdisk
      pkgs.parted
      pkgs.dosfstools
      pkgs.e2fsprogs
      pkgs.cryptsetup
      pkgs.util-linux
      pkgs.coreutils
      pkgs.gnused
      pkgs.gnugrep
    ]}:$PATH

  if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo nixriot-install" >&2
    exit 1
  fi

  echo "Whole disks:"
  lsblk -dpno NAME,SIZE,MODEL,TYPE | grep -w disk || true
  echo
  read -r -p "Target disk (e.g. /dev/nvme0n1 or /dev/sda): " disk

  if [ ! -b "$disk" ] || [ "$(lsblk -dno TYPE "$disk")" != "disk" ]; then
    echo "Refusing: $disk is not a whole block device." >&2
    exit 1
  fi

  read -r -p "This ERASES ALL DATA on $disk. Type ERASE to continue: " confirm
  [ "$confirm" = "ERASE" ] || { echo "Aborted."; exit 1; }

  umount -R /mnt >/dev/null 2>&1 || true

  sgdisk --zap-all "$disk"
  sgdisk --clear \
    --new=1:0:+512M --typecode=1:ef00 --change-name=1:BOOT \
    --new=2:0:0 --typecode=2:8300 --change-name=2:nixos \
    "$disk"
  partprobe "$disk" >/dev/null 2>&1 || true
  sleep 2

  esp="$(lsblk -lnpo NAME "$disk" | sed -n '2p')"
  root="$(lsblk -lnpo NAME "$disk" | sed -n '3p')"
  if [ -z "$esp" ] || [ -z "$root" ]; then
    echo "Could not find the new partitions on $disk" >&2
    exit 1
  fi

  mkfs.fat -F 32 -n BOOT "$esp"

  cryptsetup luksFormat --type luks2 --label nixos "$root"
  cryptsetup open "$root" cryptroot
  mkfs.ext4 -F -L nixos-root /dev/mapper/cryptroot

  mkdir -p /mnt /mnt/boot
  mount /dev/mapper/cryptroot /mnt
  mount "$esp" /mnt/boot

  while :; do
    read -r -p "Username for the desktop user: " user
    case "$user" in
      ""|root)
        echo "Enter a username." >&2
        continue
        ;;
      *[!a-z0-9_-]*|[0-9_-]*)
        echo "Use lowercase letters, digits, underscore or hyphen, not starting with a digit or underscore." >&2
        continue
        ;;
    esac
    break
  done

  if [ -n "''${NIXRIOT_FLAKE:-}" ]; then
    flake_ref="$NIXRIOT_FLAKE"
  else
    flake_dir=/tmp/nixriot-flake
    rm -rf "$flake_dir"
    cp -rL /etc/nixriot "$flake_dir"
    chmod -R u+w "$flake_dir"
    sed -i "s/^\(  *\)user = \".*\";/\1user = \"$user\";/" "$flake_dir/hosts/installed/configuration.nix"
    sed -i "s/users\.users\.[A-Za-z0-9_-]* = {/users.users.$user = {/" "$flake_dir/hosts/installed/configuration.nix"
    sed -i "s/home-manager\.users\.[A-Za-z0-9_-]* = import \.\/home;/home-manager.users.$user = import .\/home;/" "$flake_dir/flake.nix"
    sed -i "s/^\(  *\)home\.username = \".*\";/\1home.username = \"$user\";/" "$flake_dir/home/default.nix"
    sed -i "s/^\(  *\)home\.homeDirectory = \".*\";/\1home.homeDirectory = \"\/home\/$user\";/" "$flake_dir/home/default.nix"
    flake_ref="$flake_dir#installed"
  fi

  nixos-install --root /mnt --flake "$flake_ref"

  echo
  echo "Set a password for the '$user' user:"
  nixos-enter --root /mnt --command "passwd $user"

  echo
  echo "NixRiot installed. Reboot into it."
''
