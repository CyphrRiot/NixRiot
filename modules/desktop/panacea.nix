{ config, lib, pkgs, ... }:
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

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

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
      mpvpaper
      swappy
      jq
      gnome-keyring

      swaylock
      tesseract
      voxtype
      wtype
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

      qt6.qtwebengine
      qt6.qtmultimedia
      qt6.qtdeclarative

      udisks2
      udiskie
      gvfs
    ];
  };
}
