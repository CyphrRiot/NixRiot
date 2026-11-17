{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.nixriot.enable {
    environment.systemPackages = with pkgs; [
      helix
      neovim
      zed-editor
      kate
      gnome-text-editor
      crush
      git
    ];
  };
}
