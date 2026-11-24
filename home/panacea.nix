{ config, lib, pkgs, panaceaSrc, ... }:
let
  # The scripts carry Arch shebangs (#!/bin/bash), which do not exist on NixOS.
  # Patch every interpreter at build time so Hyprland and activation run them
  # directly.
  patchedPanacea = pkgs.runCommand "panacea-patched" {
    nativeBuildInputs = [ pkgs.bash pkgs.python3 ];
  } ''
    mkdir -p $out
    cp -r ${panaceaSrc}/. $out/
    chmod -R u+w $out
    patchShebangs $out
  '';

  # Ship the config trees on every rebuild rather than only when absent, so a fix
  # under hypr/ or panacea/ reaches an installed machine instead of being copied
  # once at first login and never again. What is not ours to ship is excluded:
  # hypr/custom/ is the override layer Panacea sources last, settings.json is
  # written by the pill, and wallpaper.conf and hyprpaper.conf are the wallpaper
  # state that switch_theme.sh writes at run time.
  #
  # rsync by absolute path: activation should not depend on what happens to be in
  # PATH.
  refresh = name: extraExcludes: ''
    run mkdir -p "$HOME/.config"
    run ${pkgs.rsync}/bin/rsync -a --delete ${lib.concatStringsSep " " (map (e: "--exclude ${e}") extraExcludes)} \
      ${patchedPanacea}/${name}/ "$HOME/.config/${name}/"
    run chmod -R u+w "$HOME/.config/${name}"
  '';

  # First launch needs a wallpaper before the pill or switch_theme.sh has
  # written the state files. These are copied only when absent, so a chosen
  # wallpaper still survives every rebuild.
  expandHome = builtins.replaceStrings [ "~" ] [ config.home.homeDirectory ];
  defaultWallpaper = pkgs.writeText "nixriot-wallpaper.conf"
    (expandHome (builtins.readFile "${panaceaSrc}/hypr/wallpaper.conf"));
  defaultHyprpaper = pkgs.writeText "nixriot-hyprpaper.conf"
    (expandHome (builtins.readFile "${panaceaSrc}/hypr/hyprpaper.conf"));

  # Panacea ships its desktop entries with an @HOME@ placeholder that upstream's
  # install.sh substitutes. Generate them here rather than copying verbatim,
  # which would leave a literal @HOME@ in every Exec line.
  desktopFile = name: {
    text = builtins.replaceStrings
      [ "@HOME@" ]
      [ config.home.homeDirectory ]
      (builtins.readFile "${panaceaSrc}/applications/${name}.desktop");
  };

  # "open some/relative/file.gif" hands the pill a relative path, which becomes
  # file://relative and fails to load. Resolve it against the caller's directory
  # before the IPC call.
  mediaOpen = pkgs.writeShellScript "panacea-media-open" ''
    exec ${pkgs.quickshell}/bin/qs -c "${config.home.homeDirectory}/.config/panacea" \
      ipc call pill media "$(realpath -- "$1")"
  '';

  mediaDesktop = {
    text = ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=Panacea Viewer
      Comment=Images and video in the dynamic island, with trim and crop
      Exec=${mediaOpen} %f
      Icon=${config.home.homeDirectory}/.config/panacea/assets/logo-128.png
      Terminal=false
      Categories=Graphics;
      MimeType=image/png;image/jpeg;image/gif;image/webp;image/bmp;image/tiff;image/svg+xml;video/mp4;video/webm;video/x-matroska;video/quicktime;
    '';
  };
in
{
  xdg.dataFile = {
    "applications/panacea-files.desktop" = desktopFile "panacea-files";
    "applications/panacea-media.desktop" = mediaDesktop;
    "applications/panacea-text.desktop" = desktopFile "panacea-text";
  };

  home.activation.panaceaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${refresh "panacea" [ "settings.json" "clipboard_pins.json" ".whatsnew-seen" ".run_history" ]}
    ${refresh "hypr" [ "custom" "wallpaper.conf" "hyprpaper.conf" ]}
    ${refresh "foot" []}
    ${refresh "fastfetch" []}

    if [ ! -e "$HOME/.config/hypr/wallpaper.conf" ]; then
      run cp ${defaultWallpaper} "$HOME/.config/hypr/wallpaper.conf"
    fi
    if [ ! -e "$HOME/.config/hypr/hyprpaper.conf" ]; then
      run cp ${defaultHyprpaper} "$HOME/.config/hypr/hyprpaper.conf"
    fi

    run chmod -R u+x "$HOME/.config/panacea/scripts" "$HOME/.config/hypr/scripts" 2>/dev/null || true

    if [ ! -e "$HOME/.nanorc" ] && [ -f ${panaceaSrc}/nano/nanorc ]; then
      run cp ${panaceaSrc}/nano/nanorc "$HOME/.nanorc"
    fi

    run mkdir -p "$HOME/.local/bin"
    run cp -r ${patchedPanacea}/bin/. "$HOME/.local/bin/"
    run chmod -R u+w "$HOME/.local/bin"
    run chmod -R u+x "$HOME/.local/bin"

    run mkdir -p "$HOME/.config/quickshell"
    if [ ! -e "$HOME/.config/quickshell/panacea" ]; then
      run ln -sfn "$HOME/.config/panacea" "$HOME/.config/quickshell/panacea"
    fi

    if [ -x "$HOME/.config/panacea/scripts/genmonitors.sh" ] && [ -f "$HOME/.config/panacea/settings.json" ]; then
      run "$HOME/.config/panacea/scripts/genmonitors.sh" >/dev/null 2>&1 || true
    fi
    if [ -x "$HOME/.config/panacea/scripts/genbinds.sh" ] && [ -f "$HOME/.config/panacea/settings.json" ]; then
      run "$HOME/.config/panacea/scripts/genbinds.sh" >/dev/null 2>&1 || true
    fi
    if [ -x "$HOME/.config/panacea/scripts/geninput.sh" ] && [ -f "$HOME/.config/panacea/settings.json" ]; then
      run "$HOME/.config/panacea/scripts/geninput.sh" >/dev/null 2>&1 || true
    fi

    if [ -f "$HOME/.config/panacea/scripts/voxtype.config.toml" ] && [ ! -f "$HOME/.config/voxtype/config.toml" ]; then
      run mkdir -p "$HOME/.config/voxtype"
      run cp "$HOME/.config/panacea/scripts/voxtype.config.toml" "$HOME/.config/voxtype/config.toml"
    fi

    if [ -x "$HOME/.config/hypr/scripts/palette.sh" ]; then
      run mkdir -p "$HOME/.cache/panacea"
      run "$HOME/.config/hypr/scripts/palette.sh" >"$HOME/.cache/panacea/palette.log" 2>&1 || true
    fi
  '';
}
