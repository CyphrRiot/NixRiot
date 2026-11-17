# Panacea Port Notes

This file tracks the work of turning Panacea's Arch-oriented `install.sh` into
a Home Manager module. It is the largest open item in the project.

## What the current skeleton does

- Vendors Panacea's config trees under `vendor/panacea/` at the commit recorded
  in `vendor/panacea/UPSTREAM`. There is no Panacea flake input.
- Copies the vendored config trees into `~/.config` on first activation, and
  leaves them alone afterwards.
- Copies `bin/` helpers into `~/.local/bin`.
- Ships the OpenRiot wallpaper set in `hypr/wallpaper/`, with its manifest.
- Installs the runtime dependencies from nixpkgs at the system level.

## What it does not do yet

- It does not run Panacea's `hypr/scripts/palette.sh` or
  `hypr/scripts/switch_theme.sh --restore`. Those need a live Hyprland session,
  so they belong in an `exec-once` line or a systemd user unit, not in a Home
  Manager activation.
- It does not port Panacea's `settings.json` merge logic. Panacea merges user
  settings with defaults via `jq`; that should become a Home Manager option.
- It does not install the SDDM theme or the GRUB theme. Both are asset copies
  plus a config pointer, and both need a NixOS module.
- It does not handle Panacea's updater. On NixOS the flake lock is the updater.
  Panacea's own update button should be disabled or repointed.
- It does not verify that the pinned Quickshell version matches what Panacea
  expects. Check `quickshell --version` against Panacea's requirements before
  trusting the shell.

## Vendoring and sync

Panacea is vendored at the commit in `vendor/panacea/UPSTREAM`. To inspect a
newer upstream without overwriting local changes:

```sh
make vendor-panacea
make vendor-diff
```

`.vendor-panacea` is a sparse checkout that excludes wallpapers. Copy changes
from it into `vendor/panacea/` deliberately, then update `UPSTREAM` and
`LOCAL-CHANGES.md`.

## Known version risk

Panacea tracks Hyprland and Quickshell closely. nixpkgs unstable currently
carries Quickshell 0.3.2. If Panacea needs a newer API, pin a newer nixpkgs or
override the package. Do not mix a stable nixpkgs with an unstable Panacea
without testing the pair.

## First-run checklist

1. `nix flake lock` to pin every input.
2. `nix build .#nixosConfigurations.nixriot.config.system.build.toplevel`.
3. Boot the ISO, install, reboot.
4. Log in through SDDM, confirm the pill starts.
5. Run `hyprctl reload` and check the palette.
6. Test lock, screenshots, clipboard, media, and the power menu.
