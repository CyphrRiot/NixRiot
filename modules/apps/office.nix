{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.nixriot.enable {
    environment.systemPackages = with pkgs; [
      libreoffice
      zathura
      firefox
      thunderbird
      thunar
      tumbler
      file-roller
      prusa-slicer
      orca-slicer
    ];
  };
}
