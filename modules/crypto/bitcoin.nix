{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.crypto.bitcoin) {
    environment.systemPackages = [
      pkgs.bitcoin
      pkgs.bitcoind
    ];
  };
}
