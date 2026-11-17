# Local changes to vendored Panacea

Upstream: https://github.com/EnsixD/Panacea at commit
`45ddf2e11d5193779d4539ebde3ee3376c87870a` (version 1.0.24).

## What is vendored

`panacea/`, `hypr/`, `foot/`, `fish/`, `fastfetch/`, `nano/`,
`applications/`, `bin/`, `sddm/`, `LICENSE`, `VERSION`.

## What is not vendored

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

1. `hypr/wallpaper/` is replaced with the OpenRiot background set.
2. `hypr/wallpaper.conf` and `hypr/hyprpaper.conf` point at
   `~/.config/hypr/wallpaper/01.webp`.
3. Upstream `assets/logo*.png` moved to `panacea/assets/` so the shell
   finds them after the config tree is copied.
4. `hypr/scripts/switch_theme.sh` fallback now includes `*.webp`.
5. `hypr/scripts/palette.sh` is committed executable, so the activation-time
   `-x` check regenerates the palette.
6. `panacea/scripts/start.sh` drops the Arch-only QtWebEngine workaround
   (`/usr/lib/qt6/qml/QtWebEngine/...`), which cannot resolve on NixOS.
7. `panacea/scripts/update.sh` exits early unless `PANACEA_ALLOW_SELF_UPDATE=1`.
   NixRiot updates through the flake.
8. `grub/` is not vendored: NixRiot boots with systemd-boot, so the upstream
   GRUB theme is unused.

## Not yet changed

- `panacea/scripts/*.sh` still assume common Arch tool names in a few
  places. Audit and patch as each feature is exercised.
- `hypr/scripts/*.sh` still write to `~/.config` directly. That is fine
  for now because Home Manager copies the tree once and leaves it alone.
