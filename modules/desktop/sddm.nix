{ config, lib, pkgs, panaceaSrc, ... }:
let
  theme = pkgs.runCommand "sddm-theme-panacea" { } ''
    mkdir -p $out/share/sddm/themes/panacea
    cp -r ${panaceaSrc}/sddm/panacea/. $out/share/sddm/themes/panacea/
  '';
in
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.desktop.enable) {
    services.displayManager.sddm.theme = "panacea";
    environment.systemPackages = [ theme ];
    systemd.services.display-manager.restartIfChanged = false;
  };
}
