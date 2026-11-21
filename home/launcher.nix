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
    "applications/foot.desktop" = appFile {
      name = "Terminal";
      exec = "footclient";
      icon = "foot";
      categories = "System;TerminalEmulator;";
    };
    "applications/nm-connection-editor.desktop" = hiddenFile "Advanced Network Configuration";
    "applications/org.pulseaudio.pavucontrol.desktop" = hiddenFile "Volume Control";
    "applications/xterm.desktop" = hiddenFile "XTerm";
    "applications/nixos-manual.desktop" = hiddenFile "NixOS Manual";
    "applications/yazi.desktop" = hiddenFile "Yazi File Manager";

    "applications/Helix.desktop" = appFile {
      name = "Helix";
      exec = "footclient -e hx";
      icon = "helix";
      categories = "Utility;TextEditor;";
    };
    "applications/btop.desktop" = appFile {
      name = "btop++";
      exec = "footclient -e btop";
      icon = "btop";
      categories = "System;Monitor;";
    };
    "applications/crush.desktop" = appFile {
      name = "Crush AI";
      exec = "footclient -e crush";
      categories = "Utility;Development;";
    };
    "applications/signal.desktop" = appFile {
      name = "Signal";
      exec = "signal-desktop";
      icon = "signal-desktop";
      categories = "Network;Chat;";
    };
    "applications/signal-tui.desktop" = appFile {
      name = "Signal TUI";
      exec = "footclient -e gurk";
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
