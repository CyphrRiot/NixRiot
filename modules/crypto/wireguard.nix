{ config, lib, pkgs, ... }:
{
  options.nixriot.wireguard = {
    enable = lib.mkEnableOption "WireGuard interfaces";

    interfaces = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Interface definitions passed to networking.wireguard.interfaces.";
    };
  };

  config = lib.mkIf (config.nixriot.enable && config.nixriot.wireguard.enable) {
    networking.wireguard.enable = true;
    networking.wireguard.interfaces = config.nixriot.wireguard.interfaces;
    environment.systemPackages = [ pkgs.wireguard-tools ];
  };
}
