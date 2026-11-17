# NixRiot

**One flake. Complete NixOS desktop. Panacea shell, OpenRiot soul.**

NixRiot is a proposal for a full, reproducible NixOS installer that ships
NixOS, the [Panacea](https://github.com/EnsixD/Panacea) desktop shell, and the
parts of [OpenRiot](https://github.com/CyphrRiot/OpenRiot) that make sense on
Linux. It is not a remaster of the stock ISO. It is a flake that builds its own
installer image and a declarative system profile, so the same source produces
the live USB, the installed machine, and every future update.

Status: **proposal**. Nothing here is implemented yet.

---

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

---

## What it is

Three deliverables from one flake:

1. **A live ISO** built with `nixos-generators`, based on the NixOS 26.05
   graphical installer, carrying the NixRiot profile and a post-install hook.
2. **A NixOS module** (`nixriot.nix`) that declares the system: desktop,
   services, users, security, crypto, media, and the Panacea stack.
3. **A Home Manager module** that installs Panacea's dotfiles, fish, Helix,
   Crush, and the per-user OpenRiot configuration.

The installed system is the same flake the ISO was built from. There is no
second installer script to drift.

---

## Relationship to the parents

| Project | Role in NixRiot |
|---|---|
| **NixOS 26.05** | Base system, package set, kernel, bootloader, installer tooling |
| **Panacea** | Desktop shell: Hyprland, Quickshell pill, SDDM and GRUB themes, wallpapers, keybindings |
| **OpenRiot** | Feature list, visual language, fish/Helix/Crush defaults, crypto and media tooling, motd, XDG layout |

NixRiot vendors Panacea's config trees and themes under `vendor/panacea/`,
then ports `install.sh` logic into a Home Manager module. Upstream Panacea is
the reference, not a build-time dependency.

NixRiot does not fork OpenRiot. It reuses OpenRiot's dotfiles where they are
platform-neutral (fish, Helix, fastfetch, wallpapers, cursors, icons) and
reimplements the rest declaratively.

---

## Architecture

```
NixRiot/
  flake.nix                  # inputs: nixpkgs, home-manager, nixos-generators
  README.md
  modules/
    nixriot.nix              # top-level NixOS module and options
    desktop/
      panacea.nix            # Hyprland, Quickshell, portals, session
      theme.nix              # fonts, cursors, icons, wallpapers, palette
      sddm.nix               # login theme
      grub.nix               # boot theme
    apps/
      shell.nix              # fish, foot, eza, zoxide, ripgrep, btop
      editors.nix            # Helix, Zed, Kate, Crush
      media.nix              # mpv, mpd, rmpc, transmission, yt-dlp
      office.nix             # LibreOffice, zathura, Firefox
      printing.nix           # PrusaSlicer / OrcaSlicer
    crypto/
      monero.nix             # monero-gui, wallet paths
      bitcoin.nix            # bitcoin-qt
      wireguard.nix          # networking.wireguard
    security/
      hardening.nix          # SSH, firewall, MAC randomization
      backup.nix             # restic, Proton Drive via rclone
  home/
    panacea.nix              # Home Manager port of Panacea install.sh
    fish.nix
    helix.nix
    crush.nix
    xdg.nix
  iso/
    configuration.nix        # live image, Calamares, post-install
  installer/
    calamares/               # branding, modules, post-install script
  vendor/
    panacea/                 # vendored config trees, themes, wallpapers
      UPSTREAM               # pinned Panacea commit
      hypr/wallpaper/        # OpenRiot wallpaper set
  hosts/
    example/                 # reference host config
```

### Installer flow

1. Boot the NixRiot ISO. The live session is the NixOS graphical installer
   (GNOME live environment, Calamares).
2. Calamares partitions the disk, creates the user, and selects the NixRiot
   profile.
3. The post-install hook writes the flake reference into `/mnt/etc/nixos`,
   copies the host config, and runs `nixos-install --flake`.
4. First boot applies Home Manager, which installs Panacea and the OpenRiot
   user configuration.
5. Updates are `nixos-rebuild switch --flake` or `nix flake update` plus a
   rebuild. No package drift, no partial upgrades.

A CLI path (`nixos-install --flake`) remains available for headless installs
and for anyone who does not want Calamares.

---

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
| Crush | **Port** | Package if absent from nixpkgs |
| fastfetch + motd | **Reuse** | Home Manager |
| Bibata cursor, Kora icons | **Reuse** | Packaged assets |
| Nerd Fonts | **Reuse** | nixpkgs fonts |
| Wallpaper sets | **Reuse** | OpenRiot set, vendored under `vendor/panacea/hypr/wallpaper` |
| Screenshots | **Port** | `grim`, `slurp`, `wl-clipboard` |
| Screen recording | **Port** | `wf-recorder` |
| Clipboard history | **Port** | `cliphist` |
| Monero GUI | **Port** | nixpkgs `monero-gui` |
| Bitcoin Core | **Port** | nixpkgs `bitcoind`, `bitcoin-qt` |
| WireGuard | **Port** | `networking.wireguard` |
| Transmission | **Port** | nixpkgs `transmission-gtk` |
| mpv, mpd, rmpc | **Port** | nixpkgs |
| Proton Drive sync | **Port** | `rclone` systemd user timer |
| Signal (gurk) | **Port** | nixpkgs if available, else package |
| LibreOffice, Firefox, Zed, Kate | **Port** | nixpkgs |
| 3D printing | **Port** | PrusaSlicer or OrcaSlicer |
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

---

## Build and use

Prerequisites: a Nix installation with flakes enabled, about 40 GB free, and
the NixOS 26.05 ISO already on hand for reference
(`~/Code/ISOs/NixOS.iso`).

```sh
git clone <nixriot-remote> ~/Code/NixRiot
cd ~/Code/NixRiot

# Build the live ISO
nix build .#iso

# Install from the running ISO. The live image carries this repo at
# /etc/nixriot, so the flake is available without network access to Git.
sudo nixos-install --flake /etc/nixriot#nixriot

# Rebuild an installed system
sudo nixos-rebuild switch --flake .#nixriot
```

The stock ISO is `nixos-graphical-26.05-x86_64` (GNOME live session). NixRiot
does not modify that image in place. It builds a new image from the same
nixpkgs revision, which keeps the installer and the installed system in sync.

Current state: the flake, the NixOS modules, the Home Manager modules, and the
Calamares ISO config are written. The ISO is a stock graphical installer with
this repo at `/etc/nixriot`. The Calamares post-install hook that runs
`nixos-install --flake` automatically is the next item, not yet implemented.
See `docs/Panacea-Port.md` for the Panacea-specific work.

The example host assumes the user `riot`, the root label `nixos`, and the ESP
label `BOOT`. Change `hosts/example/configuration.nix` and
`hosts/example/hardware-configuration.nix`, or regenerate the hardware config
with `nixos-generate-config`, before installing on real hardware.

---

## Milestones

| Phase | Deliverable | Exit criteria |
|---|---|---|
| 0 | Flake skeleton, `nixosConfigurations.nixriot` | `nix flake check` passes, system builds |
| 1 | Panacea Home Manager module | Hyprland session starts, pill runs, keybindings work |
| 2 | Theme and assets | Fonts, cursors, icons, wallpapers, SDDM, GRUB |
| 3 | OpenRiot app modules | fish, Helix, Crush, media, crypto, security |
| 4 | ISO and Calamares | ISO boots, installs, first boot reaches the desktop |
| 5 | Parity audit | Every row in the parity table is verified or explicitly cut |
| 6 | Release | Tagged flake, checksums, install notes |

---

## Risks

- **Panacea is Arch-first.** Its `install.sh` assumes pacman, AUR, and
  systemd unit names. The Home Manager port is the largest single work item.
- **Quickshell and Hyprland versions must match.** Panacea tracks Hyprland
  closely. NixRiot must pin both and test the pair.
- **Some Panacea features need packaging.** `voxtype`, `mpvpaper`, and
  `hyprsunset` may not be in nixpkgs at the required versions.
- **Calamares on NixOS is thin.** The graphical installer works, but custom
  post-install logic must be tested on UEFI and BIOS, with and without LUKS.
- **The ISO is large.** A graphical live image plus Panacea assets will exceed
  the stock 3.9 GB. Budget for a 5 to 6 GB USB.

---

## Non-goals

- Replacing Panacea upstream. NixRiot packages it, it does not fork it.
- Replacing OpenRiot on OpenBSD. NixRiot is the Linux sibling, not a port.
- Supporting every OpenRiot game or every OpenBSD hardware quirk.
- Shipping user secrets, wallet files, or `crypto.toml`.

---

## Licence and credits

NixRiot's own code is MIT. Panacea is MIT. OpenRiot is MIT. Wallpapers, fonts,
and bundled assets keep their original authors' terms.

- [NixOS](https://nixos.org)
- [Panacea](https://github.com/EnsixD/Panacea)
- [OpenRiot](https://github.com/CyphrRiot/OpenRiot)
- [Hyprland](https://hyprland.org)
- [Quickshell](https://quickshell.org)
