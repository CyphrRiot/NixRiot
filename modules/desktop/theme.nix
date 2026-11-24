{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.desktop.enable) {
    fonts.packages = with pkgs; [
      (runCommand "jetbrains-mono-nerd-subset" { } ''
        mkdir -p $out/share/fonts/truetype
        src=${nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono
        for w in Regular Bold Italic BoldItalic; do
          cp "$src/JetBrainsMonoNerdFont-$w.ttf" $out/share/fonts/truetype/
        done
      '')
      material-design-icons
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-lgc-plus
    ];

    fonts.fontconfig.defaultFonts.monospace = [ "JetBrainsMono Nerd Font" ];

    environment.systemPackages = with pkgs; [
      (runCommand "nixriot-cursors" { } ''
        mkdir -p $out/share/icons
        for t in Bibata-Modern-Ice Bibata-Modern-Classic; do
          cp -r ${bibata-cursors}/share/icons/$t $out/share/icons/
        done
      '')
      kora-icon-theme
      gnome-themes-extra
    ];

    environment.sessionVariables = {
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";
    };
  };
}
