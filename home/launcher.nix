{ ... }:
let
  hiddenFile = name: {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=${name}
      NoDisplay=true
    '';
  };

  appFile =
    { name, exec, icon ? null, categories ? "Utility;" }:
    {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=${name}
        Exec=${exec}
        Categories=${categories}
        Terminal=false
        ${if icon != null then "Icon=${icon}" else ""}
      '';
    };
in
{
  xdg.dataFile = {
    "applications/footclient.desktop" = hiddenFile "Foot Client";
    "applications/foot-server.desktop" = hiddenFile "Foot Server";
    "applications/nm-connection-editor.desktop" = hiddenFile "Advanced Network Configuration";
    "applications/thunar-settings.desktop" = hiddenFile "Thunar Preferences";
    "applications/thunar-bulk-rename.desktop" = hiddenFile "Bulk Rename";
    "applications/org.pulseaudio.pavucontrol.desktop" = hiddenFile "Volume Control";
    "applications/xterm.desktop" = hiddenFile "XTerm";
    "applications/nixos-manual.desktop" = hiddenFile "NixOS Manual";
    "applications/yazi.desktop" = hiddenFile "Yazi File Manager";

    "applications/Helix.desktop" = appFile {
      name = "Helix";
      exec = "foot -e hx";
      icon = "helix";
      categories = "Utility;TextEditor;";
    };
    "applications/btop.desktop" = appFile {
      name = "btop++";
      exec = "foot -e btop";
      icon = "btop";
      categories = "System;Monitor;";
    };
    "applications/crush.desktop" = appFile {
      name = "Crush AI";
      exec = "foot -e crush";
      categories = "Utility;Development;";
    };
    "applications/signal.desktop" = appFile {
      name = "Signal";
      exec = "foot -e gurk";
      categories = "Network;Chat;";
    };
    "applications/proton-mail.desktop" = appFile {
      name = "Proton Mail";
      exec = "firefox https://mail.proton.me/inbox";
      categories = "Network;Email;";
    };
    "applications/x.desktop" = appFile {
      name = "X";
      exec = "firefox https://x.com/";
      categories = "Network;News;";
    };
  };
}
