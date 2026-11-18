# NixRiot Design

Design notes for NixRiot. The user-facing manual is `../README.md`; this file is
the reasoning, architecture, and planning behind it.

Status: living document. Last updated 2026-11-16.

## Why this exists

OpenRiot is an OpenBSD desktop. Its installer is a Go binary that calls
`pkg_add`, copies dotfiles, and runs shell commands. That model does not
translate to NixOS, where the package manager is the configuration and the
configuration is the system.

OpenRiot also has a documented Hyprland migration proposal
(`docs/Hyprland.md` in the OpenRiot tree). It is blocked on packaging the
Hyprland stack in OpenBSD ports and on rewriting roughly 7,000 lines of X11
integration. NixOS already has Hyprland, Quickshell, Wayland, and the whole
graphics stack packaged and tested. Panacea already targets Hyprland.

NixRiot takes the shortest honest path: keep OpenRiot's taste, drop OpenRiot's
OpenBSD-specific plumbing, and let Nix own installation and updates.

## What it is

Three deliverables from one flake:

1. A live ISO built with `nixos-generators`, based on the NixOS 26.05 graphical
   installer, carrying the NixRiot profile and an install command.
2. A NixOS module (`modules/nixriot.nix`) that declares the system: desktop,
   services, users, security, crypto, media, and the Panacea stack.
3. A Home Manager module that installs Panacea's dotfiles, fish, Helix, Crush,
   and the per-user OpenRiot configuration.

The installed system is the same flake the ISO was built from. There is no
second installer script to drift.

## Relationship to the parents

| Project | Role in NixRiot |
|---|---|
| **NixOS 26.05** | Base system, package set, kernel, bootloader, installer tooling |
| **Panacea** | Desktop shell: Hyprland, Quickshell pill, SDDM theme, wallpapers, keybindings |
| **OpenRiot** | Feature list, visual language, fish/Helix/Crush defaults, crypto and media tooling, motd, XDG layout |

NixRiot carries Panacea's config trees and themes under `panacea/`, then
ports `install.sh` logic into a Home Manager module. Upstream Panacea is the
reference, not a build-time dependency.

NixRiot does not fork OpenRiot. It reuses OpenRiot's dotfiles where they are
platform-neutral (fish, Helix, fastfetch, wallpapers, cursors, icons) and
reimplements the rest declaratively.

## Architecture

```
NixRiot/
  flake.nix                  # inputs: nixpkgs, home-manager, nixos-generators
  _config.yml, _layouts/, assets/   # Jekyll GitHub Pages site
  modules/
    nixriot.nix              # top-level NixOS module and options
    desktop/
      panacea.nix            # Hyprland, Quickshell, portals, session
      theme.nix              # fonts, cursors, icons
      sddm.nix               # login theme
    apps/
      shell.nix              # fish, starship, zoxide, ripgrep, btop
      editors.nix            # Helix, gnome-text-editor, Crush
      media.nix              # mpv, mpd, rmpc, transmission, yt-dlp
      office.nix             # LibreOffice, zathura, Firefox
      games.nix              # optional curated game set (off by default)
    crypto/
      monero.nix             # monero-gui
      bitcoin.nix            # Bitcoin Core and Bitcoin Qt
      wireguard.nix          # networking.wireguard
    security/
      hardening.nix          # SSH, firewall, sysctl, MAC randomization
      backup.nix             # restic, rclone
  home/
    panacea.nix              # Home Manager port of Panacea install.sh
    fish.nix
    helix.nix
    crush.nix
    xdg.nix
  iso/
    configuration.nix        # live image, install command with LUKS
  panacea/                   # Panacea's config trees, themes, wallpapers
    UPSTREAM                 # pinned Panacea commit, kept for provenance
    hypr/wallpaper/          # NixRiot wallpaper set
  hosts/
    example/                 # reference host config
    installed/               # target of `nixriot-install` (LUKS root)
```

### Installer flow

1. Build the ISO with `nix build .#iso`.
2. Boot it. It comes up as the NixRiot desktop (Panacea), autologged in as
   `nixos`, and opens `nixriot-install` in a terminal by itself. The repo for
   the install is at `/etc/nixriot`.
3. `nixriot-install` partitions the chosen disk (512M ESP labeled `BOOT`,
   remainder LUKS), formats the encrypted root, mounts `/mnt`, copies the
   image's own tree to `/mnt/etc/nixriot` with the chosen username, and runs
   `nixos-install --root /mnt --flake /mnt/etc/nixriot#installed`.
4. First boot applies Home Manager, which installs Panacea and the OpenRiot
   user configuration.
5. Updates are `nixos-rebuild switch --flake` or `nix flake update` plus a
   rebuild. No package drift, no partial upgrades.

A manual `nixos-install --flake /etc/nixriot#installed` remains available for
headless installs.

## Feature parity

OpenRiot features mapped to NixRiot. "Port" means the feature is reimplemented
declaratively. "Reuse" means the existing config or asset is copied.

| OpenRiot feature | NixRiot | Notes |
|---|---|---|
| i3 tiling | **Replaced** | Hyprland via Panacea |
| Polybar | **Replaced** | Panacea pill (Quickshell) |
| Rofi launcher | **Replaced** | Panacea launcher and launchpad |
| Dunst notifications | **Replaced** | Panacea notification daemon |
| i3lock | **Replaced** | Panacea lock screen |
| picom, feh, maim | **Replaced** | Hyprland compositor, hyprpaper, grim/slurp |
| fish + starship prompt | **Reuse** | Home Manager |
| Helix | **Reuse** | nixpkgs `helix` |
| Crush | **Port** | nixpkgs `crush` |
| fastfetch + motd | **Reuse** | Home Manager |
| Bibata cursor, Kora icons | **Reuse** | Packaged assets |
| Nerd Fonts | **Reuse** | nixpkgs fonts |
| Wallpaper sets | **Own** | NixRiot set, shipped in `panacea/hypr/wallpaper` |
| Screenshots | **Port** | `grim`, `slurp`, `wl-clipboard` |
| Screen recording | **Port** | `wf-recorder` |
| Clipboard history | **Port** | `cliphist` |
| Monero GUI | **Port** | nixpkgs `monero-gui` |
| Bitcoin Core | **Port** | nixpkgs `bitcoind`, `bitcoin` |
| WireGuard | **Port** | `networking.wireguard` |
| Transmission | **Port** | nixpkgs `transmission_4-gtk` |
| mpv, mpd, rmpc | **Port** | nixpkgs |
| Proton Drive sync | **Port** | `rclone` systemd user timer |
| Signal (gurk) | **Port** | nixpkgs `gurk-rs` |
| LibreOffice, Firefox | **Port** | nixpkgs |
| Backup and restore | **Port** | `restic` |
| Disk manager | **Port** | `gnome-disks` or `gparted` |
| MAC randomization | **Port** | NetworkManager setting |
| SSH hardening | **Port** | NixOS options |
| XDG user directories | **Port** | Home Manager |
| Crypto config (`crypto.toml`) | **User-owned** | Never shipped, never overwritten |
| Control center | **Replaced** | Panacea settings |
| Games bundle | **Optional** | Curated subset, opt-in module |

### Dropped, and why

| OpenRiot item | Reason |
|---|---|
| `pkg_add` installer and OpenBSD firmware | NixOS has no equivalent and does not need one |
| Xenodm, Xenocara, X11 hardening | Wayland stack replaces X11 |
| OpenBSD version tracking | NixOS channels and flake locks replace it |
| `openriot` Go binary installer paths | Nix modules replace imperative install |
| OpenBSD-specific hardware notes | NixOS hardware profiles replace them |
| GRUB and its theme | NixRiot boots with systemd-boot |
| 3D printing (PrusaSlicer, OrcaSlicer) | Cut; not part of the desktop |

## Open work

Ordered by priority.

1. Verify the built ISO installs and boots to the desktop (UEFI, then BIOS).
2. Offline ISO inputs, so the installer needs no network.
3. SDDM theme may need a Qt5/Qt6 shim if this nixpkgs' greeter is Qt6.
4. Runtime checks: gvfs MTP, tesseract (English), Quickshell version versus
   Panacea's expectations.

## Milestones

| Phase | Deliverable | Exit criteria | State |
|---|---|---|---|
| 0 | Flake skeleton, `nixosConfigurations.nixriot` | `nix flake check` passes, system builds | flake check passes |
| 1 | Panacea Home Manager module | Hyprland session starts, pill runs, keybindings work | written, not booted |
| 2 | Theme and assets | Fonts, cursors, icons, wallpapers, SDDM | written |
| 3 | OpenRiot app modules | fish, Helix, Crush, media, crypto, security | written |
| 4 | ISO and install command | ISO boots, installs, first boot reaches the desktop | ISO builds, not yet booted |
| 5 | Parity audit | Every parity row verified or explicitly cut | pending |
| 6 | Release | Tagged flake, checksums, install notes | pending |

## Risks

- **Panacea is Arch-first.** Its `install.sh` assumes pacman, AUR, and systemd
  unit names. The Home Manager port is the largest single work item.
- **Quickshell and Hyprland versions must match.** Panacea tracks Hyprland
  closely. NixRiot must pin both and test the pair.
- **The ISO is large.** A graphical live image plus Panacea assets will exceed
  the stock 3.9 GB. Budget for a 5 to 6 GB USB.

## Non-goals

- Replacing Panacea upstream. NixRiot packages it, it does not fork it.
- Replacing OpenRiot on OpenBSD. NixRiot is the Linux sibling, not a port.
- Supporting every OpenRiot game or every OpenBSD hardware quirk.
- Shipping user secrets, wallet files, or `crypto.toml`.
