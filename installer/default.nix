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
      pkgs.curl
    ]}:$PATH

  LOG=/tmp/nixriot-install.log
  stage=/tmp/nixriot-stage
  repo="https://github.com/CyphrRiot/NixRiot"

  exec > >(tee -a "$LOG") 2>&1
  trap 'echo; echo "Installer stopped at line $LINENO."; echo "Log: $LOG" >&2' ERR

  if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo nixriot-install" >&2
    exit 1
  fi

  echo "NixRiot installer. Log: $LOG"
  echo

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

  # Stage the tree and check the network BEFORE touching any disk, so a
  # failure here costs nothing.
  if [ -n "''${NIXRIOT_FLAKE:-}" ]; then
    flake_ref="$NIXRIOT_FLAKE"
    echo "Using the flake at $flake_ref"
  else
    echo "Staging the install tree in $stage ..."
    rm -rf "$stage"
    mkdir -p "$stage"

    if [ "''${NIXRIOT_USE_REPO:-0}" = "1" ] && git clone --depth 1 "$repo" "$stage" >/dev/null 2>&1; then
      :
    else
      src=$(readlink -f /etc/nixriot)
      cp -rL "$src/." "$stage/"
      chmod -R u+w "$stage"
      git -C "$stage" init -q
      git -C "$stage" remote add origin "$repo" 2>/dev/null || true
      git -C "$stage" add -A
      git -C "$stage" -c user.name=nixriot -c user.email=nixriot@localhost \
        commit -q -m "image snapshot" >/dev/null
    fi

    printf '{\n  nixriotUser = "%s";\n}\n' "$user" > "$stage/hosts/installed/local.nix"
    git -C "$stage" add hosts/installed/local.nix
    git -C "$stage" -c user.name=nixriot -c user.email=nixriot@localhost \
      commit -q -m "local: desktop user" >/dev/null 2>&1 || true
  fi

  if [ "''${NIXRIOT_OFFLINE:-0}" != "1" ]; then
    if curl -fsS --max-time 15 -o /dev/null https://cache.nixos.org/nix-cache-info; then
      :
    else
      echo "No network to cache.nixos.org; continuing, the image is offline-capable." >&2
    fi
  fi

  echo
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

  if [ -z "''${NIXRIOT_FLAKE:-}" ]; then
    mkdir -p /mnt/etc
    cp -a "$stage" /mnt/etc/nixriot
    flake_ref="/mnt/etc/nixriot#installed"
  fi

  echo
  echo "Installing. This needs the network and can take a while."
  if ! nixos-install --root /mnt --flake "$flake_ref"; then
    echo
    echo "nixos-install FAILED. The disk is partitioned, but nothing was installed." >&2
    echo "Fix the cause and run the installer again. Log: $LOG" >&2
    exit 1
  fi

  echo
  echo "Set a password for the '$user' user:"
  nixos-enter --root /mnt --command "passwd $user"

  echo
  echo "NixRiot installed. Reboot into it."
''
