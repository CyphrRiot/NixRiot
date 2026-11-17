{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.nixriot.enable {
    environment.systemPackages = with pkgs; [
      restic
      rclone
    ];
  };
}
