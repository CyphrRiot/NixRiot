{ lib, ... }:
let
  local = import ./local.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixriot.nix
  ];

  assertions = [
    {
      assertion = local.nixriotUser != "CHANGEME";
      message = "hosts/installed/local.nix is the repository template. Build from the machine's /etc/nixriot copy, or set the real username in local.nix.";
    }
  ];

  nixriot = {
    enable = true;
    user = local.nixriotUser;
    hostName = lib.mkDefault "nixriot";
    desktop.enable = lib.mkDefault true;
    apps = lib.mkDefault true;
    plymouth = lib.mkDefault false;
    autologin = lib.mkDefault true;
    media.transmission = lib.mkDefault true;
  } // (local.nixriot or { });

  home-manager.users.${local.nixriotUser} = import ../../home;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
}
