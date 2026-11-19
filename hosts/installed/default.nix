{ lib, ... }:
let
  local = import ./local.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixriot.nix
  ];

  nixriot = {
    enable = true;
    user = local.nixriotUser;
    hostName = lib.mkDefault "nixriot";
    desktop.enable = lib.mkDefault true;
    apps = lib.mkDefault true;
    plymouth = lib.mkDefault true;
    autologin = lib.mkDefault true;
    media.transmission = lib.mkDefault true;
  } // (local.nixriot or { });

  home-manager.users.${local.nixriotUser} = import ../../home;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
