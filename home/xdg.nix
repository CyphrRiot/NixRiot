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
      "inode/directory" = "thunar.desktop";

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

  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScripts.mpris ];
  };
}
