{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.apps) {
    environment.systemPackages = with pkgs; [
      zathura
      firefox
      file-roller
    ] ++ lib.optionals config.nixriot.office [ libreoffice ];

    environment.etc."firefox/policies/policies.json".text = ''
      {
        "policies": {
          "Preferences": {
            "ui.systemUsesDarkTheme": 1,
            "browser.theme.content-theme": 1,
            "browser.theme.toolbar-theme": 1
          }
        }
      }
    '';
  };
}
