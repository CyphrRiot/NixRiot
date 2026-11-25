{ lib, ... }:
let
  local = import ./local.nix;
  features =
    if builtins.pathExists ./features.nix then import ./features.nix else { };
  featureConfig =
    lib.optionalAttrs (features ? packages) { packages = features.packages; }
    // lib.optionalAttrs (features ? office) { office = features.office; }
    // lib.optionalAttrs (features ? claude) { claude = features.claude; }
    // lib.optionalAttrs (features ? games) { games = features.games; }
    // lib.optionalAttrs (features ? transmission) { media.transmission = features.transmission; }
    // lib.optionalAttrs
         (features ? monero || features ? bitcoin)
         {
           crypto = lib.filterAttrs (_: v: v != null) {
             monero = features.monero or null;
             bitcoin = features.bitcoin or null;
           };
         };
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
    plymouth = lib.mkDefault true;
    autologin = lib.mkDefault true;
    media.transmission = lib.mkDefault true;
  } // (local.nixriot or { }) // featureConfig;

  home-manager.users.${local.nixriotUser} = import ../../home;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
}
