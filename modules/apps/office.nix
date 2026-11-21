{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.apps) {
    environment.systemPackages = with pkgs; [
      zathura
      firefox
      file-roller
    ] ++ lib.optionals config.nixriot.office [ libreoffice ];
  };
}
