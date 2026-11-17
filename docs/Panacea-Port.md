# Panacea Port Notes

This file tracks the work of turning Panacea's Arch-oriented `install.sh` into
a Home Manager module.

## What the port does

- Carries Panacea's config trees under `panacea/`, at the commit recorded in
  `panacea/UPSTREAM`. There is no Panacea flake input; the trees are NixRiot's
  own copies and are edited in place.
- Copies the config trees into `~/.config` on first activation and leaves them
  alone afterwards, so later edits by the user survive.
- Copies `bin/` helpers into `~/.local/bin`.
- Copies the desktop entries, with Panacea's `@HOME@` placeholder substituted.
- Ships the NixRiot wallpaper set in `hypr/wallpaper/`, with its manifest.
- Runs `hypr/scripts/palette.sh` at activation, which lays the palette out
  across foot, fish, zed, btop, neovim and obsidian.
- Installs the runtime dependencies from nixpkgs at the system level.

## What it does not do yet

- It does not port Panacea's `settings.json` merge logic. Panacea merges user
  settings with defaults via `jq`; that should become a Home Manager option.
- GRUB is not used; NixRiot boots with systemd-boot, so no boot theme is
  installed.
- It does not verify that the pinned Quickshell version matches what Panacea
  expects. Check `quickshell --version` against Panacea's requirements before
  trusting the shell.

## Upstream relationship

Panacea is MIT, so `panacea/UPSTREAM` and `panacea/LICENSE` stay for
attribution. There is no sync tooling: the trees are first-party now, edited
directly, and `panacea/LOCAL-CHANGES.md` records every deliberate difference
from upstream. To compare against a newer upstream release, clone Panacea
separately and diff by hand.

## Known version risk

Panacea tracks Hyprland and Quickshell closely. nixpkgs unstable currently
carries Quickshell 0.3.2. If Panacea needs a newer API, pin a newer nixpkgs or
override the package. Do not mix a stable nixpkgs with an unstable Panacea
without testing the pair.

## First-run checklist

1. `nix flake lock` to pin every input.
2. `nix build .#nixosConfigurations.installed.config.system.build.toplevel`.
3. Boot the ISO, install, reboot.
4. Log in through SDDM, confirm the pill starts.
5. Run `hyprctl reload` and check the palette.
6. Test lock, screenshots, clipboard, media, and the power menu.
