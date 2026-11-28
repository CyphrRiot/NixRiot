{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.apps) {
    environment.systemPackages = with pkgs; [
      zathura
      firefox
      file-roller
      gnome-calculator
    ] ++ lib.optionals config.nixriot.office [ libreoffice ];

    environment.etc."firefox/extensions/matte-black.xpi".source = pkgs.fetchurl {
      url = "https://addons.mozilla.org/firefox/downloads/file/4226379/matte_black_v1-2024.1.24.xpi";
      hash = "sha256-ajwfWSuxsevEEVgLJqsl+4Jqpn4jEjcg5Br9t6JxA5o=";
    };

    environment.etc."firefox/policies/policies.json".text = ''
      {
        "policies": {
          "Preferences": {
            "ui.systemUsesDarkTheme": 1,
            "browser.theme.content-theme": 1,
            "browser.theme.toolbar-theme": 1
          },
          "Extensions": {
            "Install": ["file:///etc/firefox/extensions/matte-black.xpi"]
          }
        }
      }
    '';
  };
}
