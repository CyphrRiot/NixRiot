{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.desktop.enable) {
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      material-design-icons
      noto-fonts
      noto-fonts-emoji
      noto-fonts-cjk
      noto-fonts-extra
    ];

    environment.systemPackages = with pkgs; [
      bibata-cursors
      kora-icon-theme
      papirus-icon-theme
    ];

    environment.sessionVariables = {
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";
    };
  };
}
