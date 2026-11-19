{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ "${modulesPath}/installer/scan/not-detected.nix" ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "dm_crypt"
    "virtio_pci"
    "virtio_blk"
  ];

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-label/nixos";

  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
