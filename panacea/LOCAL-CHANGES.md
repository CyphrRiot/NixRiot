# Panacea local changes

Upstream: https://github.com/EnsixD/Panacea at commit
`45ddf2e11d5193779d4539ebde3ee3376c87870a` (version 1.0.24).

The trees below are NixRiot's own copies, edited in place. There is no sync
tooling; `UPSTREAM` and `LICENSE` stay for attribution.

## What is carried

`panacea/`, `hypr/`, `foot/`, `fastfetch/`, `nano/`,
`applications/`, `bin/`, `sddm/`, `LICENSE`, `VERSION`.

## What is not carried

- `install.sh`: the Arch installer. NixRiot replaces it with Nix modules.
- `docs/`, `README.md`, `AGENTS.md`, `.gitignore`, `graphify-out/`,
  `Panacea Vault/`: upstream housekeeping.
- `niri/`: experimental second compositor, not used here.
- `grub/`: NixRiot boots with systemd-boot, so the GRUB theme is not shipped.
- `assets/`: only the `logo*.png` files are kept, under
  `panacea/assets/` because the shell reads `~/.config/panacea/assets/`.
- `wallpapers/`: upstream set is third-party work with mixed terms and is
  not redistributed.

## Changes made

1. `hypr/wallpaper/` is replaced with the NixRiot wallpaper set, `00.webp`
   through `25.webp`, generated for the project.
2. `hypr/wallpaper.conf` and `hypr/hyprpaper.conf` point at
   `~/.config/hypr/wallpaper/16.webp`.
3. Upstream `assets/logo*.png` moved to `panacea/assets/` so the shell
   finds them after the config tree is copied.
4. `hypr/scripts/switch_theme.sh` fallback now includes `*.webp`.
5. `hypr/scripts/palette.sh` is committed executable, so the activation-time
   `-x` check regenerates the palette.
6. `panacea/scripts/start.sh` drops the Arch-only QtWebEngine workaround
   (`/usr/lib/qt6/qml/QtWebEngine/...`), which cannot resolve on NixOS.
7. `panacea/scripts/update.sh` is an adapter between Panacea's update UI and
   NixOS: `check` reads the status file that `nixriot-update` writes on its
   timer and answers in Panacea's key=value format, and `apply` starts the
   privileged `nixriot-update` service. The upstream updater is not used.
8. `grub/` is not carried: NixRiot boots with systemd-boot, so the upstream
   GRUB theme is unused.
9. `hypr/custom/keybinds.conf` and `hypr/custom/keybindings.lua` carry an
   OpenRiot-compatible keybinding overlay: the launcher, browser, file manager,
   process viewer, editor, Crush, music player, clipboard, power menu, and
   screenshot move back to OpenRiot's keys.
10. `hypr/lua/binds_data.lua`, `hypr/lua/monitors_data.lua` and
    `hypr/lua/input_data.lua` ship as empty defaults. Upstream lets them be
    absent and relies on `pcall`; shipping them keeps Hyprland's Lua loader
    from logging a missing-module error before the settings panel generates
    them. `genbinds.sh`, `genmonitors.sh` and `geninput.sh` overwrite them.
11. `hypr/lua/keybindings.lua` used `pcall(require("lua.binds_data"))`, which
    runs `require` before `pcall` and so is not guarded at all: a missing
    `binds_data.lua` aborts the whole config with a dump of every search path.
    Changed to `pcall(require, "lua.binds_data")`, matching `monitors.lua`,
    `input.lua` and `windowrules.lua`.
12. `hypr/theme.lua` uses `gaps_in = 0`, `gaps_out = 0`, `rounding = 8`,
    matching OpenRiot: flush tiled windows, rounded corners, and a 1px border
    on every window. Upstream used 5/5 and rounding 12.
13. `hypr/lua/windowrules.lua` drops the `no-gaps-wtv1` rule, which zeroed
    `border_size` and `rounding` on any workspace with exactly one tiled
    window. That made a lone window borderless, which is the opposite of
    OpenRiot's `default_border pixel 1` with `smart_gaps off`. The `no-gaps-f1`
    rule stays: true fullscreen should have neither border nor rounding.
14. `hypr/scripts/palette.sh` now derives foot's full 16-colour ANSI palette
    from `palette.conf` and writes it to `~/.config/foot/theme`. It previously
    wrote only foreground, background and selection, so foot fell back to its
    own stock palette, which is where the terminal's green came from.

## Not yet changed

- `panacea/scripts/*.sh` still assume common Arch tool names in a few
  places. Audit and patch as each feature is exercised.
- `hypr/scripts/*.sh` still write to `~/.config` directly. That is fine
  for now because Home Manager copies the tree once and leaves it alone.
