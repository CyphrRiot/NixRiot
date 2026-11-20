{ config, lib, pkgs, panaceaSrc, ... }:
let
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
      ${panaceaSrc}/${name}/ "$HOME/.config/${name}/"
    run chmod -R u+w "$HOME/.config/${name}"
  '';

  # Panacea ships its desktop entries with an @HOME@ placeholder that upstream's
  # install.sh substitutes. Generate them here rather than copying verbatim,
  # which would leave a literal @HOME@ in every Exec line.
  desktopFile = name: {
    text = builtins.replaceStrings
      [ "@HOME@" ]
      [ config.home.homeDirectory ]
      (builtins.readFile "${panaceaSrc}/applications/${name}.desktop");
  };
in
{
  xdg.dataFile = {
    "applications/panacea-files.desktop" = desktopFile "panacea-files";
    "applications/panacea-media.desktop" = desktopFile "panacea-media";
    "applications/panacea-text.desktop" = desktopFile "panacea-text";
  };

  home.activation.panaceaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${refresh "panacea" [ "settings.json" "clipboard_pins.json" ".whatsnew" ]}
    ${refresh "hypr" [ "custom" "wallpaper.conf" "hyprpaper.conf" ]}
    ${refresh "foot" []}
    ${refresh "fastfetch" []}

    run chmod -R u+x "$HOME/.config/panacea/scripts" "$HOME/.config/hypr/scripts" 2>/dev/null || true

    if [ ! -e "$HOME/.nanorc" ] && [ -f ${panaceaSrc}/nano/nanorc ]; then
      run cp ${panaceaSrc}/nano/nanorc "$HOME/.nanorc"
    fi

    run mkdir -p "$HOME/.local/bin"
    run cp -r ${panaceaSrc}/bin/. "$HOME/.local/bin/"
    run chmod -R u+w "$HOME/.local/bin"
    run chmod -R u+x "$HOME/.local/bin"

    run mkdir -p "$HOME/.config/quickshell"
    if [ ! -e "$HOME/.config/quickshell/panacea" ]; then
      run ln -sfn "$HOME/.config/panacea" "$HOME/.config/quickshell/panacea"
    fi

    if [ -x "$HOME/.config/panacea/scripts/genbinds.sh" ] && [ -f "$HOME/.config/panacea/settings.json" ]; then
      run "$HOME/.config/panacea/scripts/genbinds.sh" >/dev/null 2>&1 || true
    fi
    if [ -x "$HOME/.config/panacea/scripts/genmonitors.sh" ] && [ -f "$HOME/.config/panacea/settings.json" ]; then
      run "$HOME/.config/panacea/scripts/genmonitors.sh" >/dev/null 2>&1 || true
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
