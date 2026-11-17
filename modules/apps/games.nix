{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.games) {
    environment.systemPackages = with pkgs; [
      supertux
      openttd
      cataclysm-dda
      endless-sky
      angband
      brogue-ce
    ];
  };
}
