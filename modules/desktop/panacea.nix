{ config, lib, pkgs, ... }:
let
  qmlImportPath = lib.makeSearchPath "lib/qt-6/qml" [
    pkgs.qt6.qtmultimedia
  ];
in
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.desktop.enable) {
    programs.hyprland.enable = true;
    hardware.graphics.enable = true;
    services.xserver.enable = true;

    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;

    xdg.portal.enable = true;
    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];

    security.polkit.enable = true;
    security.rtkit.enable = true;
    security.pam.services.swaylock = { };
    services.gnome.gnome-keyring.enable = true;
    programs.dconf.enable = true;

    hardware.bluetooth.enable = true;
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
    services.libinput.enable = true;

    services.udisks2.enable = true;
    services.gvfs.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    networking.networkmanager.enable = true;

    services.mullvad-vpn = {
      enable = true;
      gui.enable = true;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QML2_IMPORT_PATH = qmlImportPath;
      QML_IMPORT_PATH = qmlImportPath;
    };

    environment.systemPackages = with pkgs; [
      quickshell
      hyprland
      hyprpaper
      hyprsunset
      hypridle
      foot
      fish
      grim
      slurp
      wl-clipboard
      cliphist
      wf-recorder
      cava
      libnotify
      brightnessctl
      playerctl
      pavucontrol
      networkmanagerapplet
      bluez
      bluez-tools
      upower
      power-profiles-daemon
      swappy
      jq
      gnome-keyring

      ddcutil
      wireplumber
      yazi
      xdg-utils
      glib
      pciutils
      util-linux
      file
      openssl
      python3

      qt6.qtmultimedia
      qt6.qtdeclarative

      udisks2
      udiskie
      gvfs
    ] ++ lib.optionals config.nixriot.ocr [ tesseract ]
      ++ lib.optionals config.nixriot.apps [ mpvpaper ];
  };
}
