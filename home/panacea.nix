{ config, lib, panaceaSrc, ... }:
let
  copyIfMissing = name: ''
    if [ ! -e "$HOME/.config/${name}" ]; then
      run mkdir -p "$HOME/.config"
      run cp -r ${panaceaSrc}/${name} "$HOME/.config/${name}"
      run chmod -R u+w "$HOME/.config/${name}"
    fi
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
    ${copyIfMissing "panacea"}
    ${copyIfMissing "hypr"}
    ${copyIfMissing "foot"}
    ${copyIfMissing "fastfetch"}

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
      run "$HOME/.config/hypr/scripts/palette.sh" >/dev/null 2>&1 || true
    fi
  '';
}
