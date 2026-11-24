{ pkgs, ... }:
{
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme.name = "kora";
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      size = 24;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk3.extraCss = builtins.readFile ./gtk/gtk-3.0.css;
    gtk4.extraCss = builtins.readFile ./gtk/gtk-4.0.css;
  };

  xdg.dataFile = {
    "gtksourceview-5/styles/tokyo-night.xml".source = ./text-editor/tokyo-night.xml;
    "gtksourceview-5/styles/cypherriot.xml".source = ./text-editor/cypherriot.xml;
  };

  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
      monospace-font-name = "JetBrainsMono Nerd Font 12";
    };
    "org/gnome/Lollypop" = {
      background-mode = true;
    };
    "org/gnome/TextEditor" = {
      style-scheme = "tokyo-night";
      style-variant = "dark";
    };
  };
}
