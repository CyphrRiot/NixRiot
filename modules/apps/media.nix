{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.nixriot.enable {
    environment.systemPackages = with pkgs; [
      mpv
      mpd
      rmpc
      yt-dlp
      ffmpeg
      ffmpegthumbnailer
      cava
    ] ++ lib.optionals config.nixriot.media.transmission [
      pkgs.transmission_4-gtk
    ];

    services.mpd = {
      enable = true;
      settings.music_directory = "/home/${config.nixriot.user}/Music";
    };

    users.users.mpd.extraGroups = [ "users" ];

    systemd.tmpfiles.rules = [
      "d /home/${config.nixriot.user}/Music 0750 ${config.nixriot.user} users -"
    ];
  };
}
