{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.apps) {
    environment.systemPackages = with pkgs; [
      mpv
      lollypop
      ffmpeg
      ffmpegthumbnailer
      cava
    ] ++ lib.optionals config.nixriot.media.transmission [
      pkgs.transmission_4-gtk
    ];

    systemd.tmpfiles.rules = [
      "d /home/${config.nixriot.user}/Music 0750 ${config.nixriot.user} users -"
    ];
  };
}
