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
  keyfile=""

  cleanup() { if [ -n "$keyfile" ]; then rm -f "$keyfile"; fi; }

  exec > >(tee -a "$LOG") 2>&1
  trap 'cleanup' EXIT
  trap 'echo; echo "Installer stopped at line $LINENO."; echo "Log: $LOG" >&2' ERR

  if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo nixriot-install" >&2
    exit 1
  fi

  dmesg -n 1 2>/dev/null || true

  noninteractive=0
  if [ -n "''${NIXRIOT_DISK:-}" ]; then
    noninteractive=1
    [ -n "''${NIXRIOT_USER:-}" ] || { echo "NIXRIOT_DISK is set but NIXRIOT_USER is not." >&2; exit 1; }
    [ -n "''${NIXRIOT_PASSPHRASE:-}" ] || { echo "NIXRIOT_DISK is set but NIXRIOT_PASSPHRASE is not." >&2; exit 1; }
    [ -n "''${NIXRIOT_PASSWORD:-}" ] || { echo "NIXRIOT_DISK is set but NIXRIOT_PASSWORD is not." >&2; exit 1; }
  fi

  if [ -n "''${NIXRIOT_USER:-}" ]; then
    user="$NIXRIOT_USER"
    case "$user" in
      root|*[!a-z0-9_-]*|[0-9_-]*)
        echo "Invalid NIXRIOT_USER: $user" >&2
        exit 1
        ;;
    esac
  else
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
  fi

  if [ -n "''${NIXRIOT_HOSTNAME:-}" ]; then
    host="$NIXRIOT_HOSTNAME"
  else
    while :; do
      read -r -p "Hostname for this machine [nixriot]: " host
      host="''${host:-nixriot}"
      case "$host" in
        -*|*-|"")
          echo "No leading or trailing hyphen." >&2
          continue
          ;;
        *[!a-z0-9-]*)
          echo "Use lowercase letters, digits and hyphens only." >&2
          continue
          ;;
      esac
      if [ "''${#host}" -gt 63 ]; then
        echo "Keep it to 63 characters or fewer." >&2
        continue
      fi
      break
    done
  fi

  host="''${host:-nixriot}"

  if [ -n "''${NIXRIOT_PASSWORD:-}" ]; then
    user_pass="$NIXRIOT_PASSWORD"
  else
    while :; do
      read -r -s -p "Password for '$user': " p1
      echo
      read -r -s -p "Confirm password: " p2
      echo
      if [ -z "$p1" ]; then
        echo "Password cannot be empty." >&2
        continue
      fi
      if [ "$p1" != "$p2" ]; then
        echo "Passwords do not match." >&2
        continue
      fi
      user_pass="$p1"
      break
    done
  fi

  if [ "''${NIXRIOT_OFFLINE:-0}" != "1" ]; then
    while ! curl -fsS --max-time 10 -o /dev/null https://cache.nixos.org/nix-cache-info; do
      echo
      echo "No network. NixRiot downloads the system from cache.nixos.org during"
      echo "the install, so it needs a connection before it touches the disk."
      echo
      echo "  Enter  retry"
      echo "  w      configure Wi-Fi / network (nmtui)"
      echo "  skip   install anyway (only if the store already has everything)"
      read -r answer
      case "$answer" in
        w|W) nmtui-connect </dev/tty >/dev/tty 2>&1 || true ;;
        skip|SKIP) break ;;
        *) : ;;
      esac
    done
  fi

  echo
  if [ "$noninteractive" = 1 ]; then
    disk="$NIXRIOT_DISK"
  else
    echo "Whole disks:"
    lsblk -dpno NAME,SIZE,MODEL,TYPE | grep -w disk || true
    echo
    read -r -p "Target disk (e.g. /dev/nvme0n1 or /dev/sda): " disk
  fi

  if [ ! -b "$disk" ] || [ "$(lsblk -dno TYPE "$disk")" != "disk" ]; then
    echo "Refusing: $disk is not a whole block device." >&2
    exit 1
  fi

  if [ "$noninteractive" = 0 ]; then
    read -r -p "This ERASES ALL DATA on $disk. Type ERASE to continue: " confirm
    [ "$confirm" = "ERASE" ] || { echo "Aborted."; exit 1; }
  fi

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

  if [ "$noninteractive" = 1 ]; then
    mkfs.fat -F 32 -n BOOT -I "$esp"
  else
    mkfs.fat -F 32 -n BOOT "$esp"
  fi

  if [ -n "''${NIXRIOT_PASSPHRASE:-}" ]; then
    luks_pass="$NIXRIOT_PASSPHRASE"
  else
    while :; do
      read -r -s -p "Disk passphrase for $root (you type this at every boot): " l1
      echo
      read -r -s -p "Confirm passphrase: " l2
      echo
      if [ -z "$l1" ]; then
        echo "Passphrase cannot be empty." >&2
        continue
      fi
      if [ "$l1" != "$l2" ]; then
        echo "Passphrases do not match." >&2
        continue
      fi
      luks_pass="$l1"
      break
    done
  fi

  keyfile=$(mktemp)
  chmod 600 "$keyfile"
  printf '%s' "$luks_pass" > "$keyfile"
  luks_opts=(--batch-mode --key-file "$keyfile")

  echo
  echo "Encrypting $root (LUKS2) ..."
  cryptsetup luksFormat --type luks2 --label nixos "''${luks_opts[@]}" "$root"

  echo "Unlocking the encrypted volume ..."
  cryptsetup open "''${luks_opts[@]}" "$root" cryptroot

  echo "Creating the root filesystem ..."
  mkfs.ext4 -F -L nixos-root /dev/mapper/cryptroot

  mkdir -p /mnt
  mount /dev/mapper/cryptroot /mnt
  mkdir -p /mnt/boot
  mount -o fmask=0077,dmask=0077 "$esp" /mnt/boot

  if [ -z "''${NIXRIOT_FLAKE:-}" ]; then
    echo
    echo "Installing the NixRiot project into /mnt/etc/nixriot ..."
    mkdir -p /mnt/etc/nixriot
    cp -rL "$(readlink -f /etc/nixriot)/." /mnt/etc/nixriot/
    chmod -R u+w /mnt/etc/nixriot

    cp /etc/nixriot-image-revision /mnt/etc/nixriot-revision 2>/dev/null \
      || echo unknown > /mnt/etc/nixriot-revision

    echo "Detecting hardware ..."
    nixos-generate-config --root /mnt --dir /mnt/etc/nixriot/hosts/installed

    printf '{\n  nixriotUser = "%s";\n  nixriot.hostName = "%s";\n}\n' "$user" "$host" > /mnt/etc/nixriot/hosts/installed/local.nix

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
  printf '%s:%s\n' "$user" "$user_pass" | nixos-enter --root /mnt --command "chpasswd"

  echo
  echo "NixRiot installed."
  sync
  umount -R /mnt 2>/dev/null || true
  cryptsetup close cryptroot 2>/dev/null || true

  if [ "''${NIXRIOT_REBOOT:-1}" = "1" ]; then
    echo "Rebooting into the installed system ..."
    systemctl reboot
  else
    echo "Reboot into it when ready."
  fi
''
