{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.crypto.monero) {
    environment.systemPackages = [ pkgs.monero-gui ];
  };
}
