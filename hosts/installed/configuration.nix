{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixriot.nix
  ];

  nixriot = {
    enable = true;
    hostName = "nixriot";
    user = "riot";
    desktop.enable = true;
    crypto = {
      monero = true;
      bitcoin = true;
    };
    media.transmission = true;
    games = false;
  };

  users.users.riot = {
    isNormalUser = true;
    group = "users";
    homeMode = "0750";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "uinput"
    ];
    initialPassword = "nixriot";
  };

  security.sudo.wheelNeedsPassword = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [ "dm_crypt" ];
  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-label/nixos";

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
}
