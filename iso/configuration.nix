{ modulesPath, lib, pkgs, ... }:
let
  nixriot-install = pkgs.writeScriptBin "nixriot-install" ''
    #!${pkgs.runtimeShell}
    set -euo pipefail

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

    nixos-install --root /mnt --flake /etc/nixriot#installed

    echo "NixRiot installed. Reboot into it."
  '';
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares.nix"
  ];

  environment.etc."nixriot".source = lib.cleanSource ../.;

  environment.systemPackages = with pkgs; [
    git
    vim
    gptfdisk
    parted
    dosfstools
    e2fsprogs
    cryptsetup
    util-linux
    nixriot-install
  ];

  services.openssh.enable = true;
  networking.networkmanager.enable = true;

  users.users.nixos.extraGroups = [ "wheel" "networkmanager" ];
}
