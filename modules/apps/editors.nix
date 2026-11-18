{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.apps) {
    environment.systemPackages = with pkgs; [
      helix
      gnome-text-editor
      crush
      git
    ];
  };
}
