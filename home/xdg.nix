{ pkgs, ... }:
{
  xdg.enable = true;

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
    desktop = "$HOME/Desktop";
    publicShare = "$HOME/Public";
    templates = "$HOME/Templates";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "application/pdf" = "org.pwmt.zathura.desktop";
      "text/markdown" = "org.gnome.TextEditor.desktop";
      "text/x-markdown" = "org.gnome.TextEditor.desktop";
      "inode/directory" = "panacea-files.desktop";

      "image/png" = "panacea-media.desktop";
      "image/jpeg" = "panacea-media.desktop";
      "image/gif" = "panacea-media.desktop";
      "image/webp" = "panacea-media.desktop";
      "image/bmp" = "panacea-media.desktop";
      "image/tiff" = "panacea-media.desktop";
      "image/svg+xml" = "panacea-media.desktop";

      "video/mp4" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
    };
  };

  xdg.dataFile = {
    "applications/mpv.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Media Player
      GenericName=Multimedia player
      Exec=mpv --player-operation-mode=pseudo-gui -- %U
      Icon=mpv
      Terminal=false
      Categories=AudioVideo;Player;
      MimeType=video/mp4;video/webm;video/x-matroska;video/quicktime;audio/mpeg;audio/flac;audio/ogg;audio/wav;
    '';
  };

  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScripts.mpris ];
  };
}
