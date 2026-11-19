# NixRiot Design

Design notes for NixRiot. The user-facing manual is `../README.md`; the durable
internals (decisions, installer contract, update mechanics, verified package
facts) are in `Internals.md`. This file is the reasoning, architecture, and
planning.

Status: living document. Last updated 2026-11-18.

## Why this exists

NixRiot is the fourth desktop we have built, and the first one whose foundation
we trust.

- **ArchRiot** was an Arch installer with hand-maintained dotfiles. It taught us
  what the desktop should feel like.
- **Omarchy** then covered much of that ground, so we stopped rather than
  duplicate it. What we could not fix on Arch was trust: the AUR means running
  code from strangers, and that is not a defensible default for a desktop you
  have to keep patched.
- **OpenBSD** came next and remains the Unix we trust most, but hardware support
  is narrow and a modern GPU desktop on it is a permanent fight. OpenRiot also
  has a documented Hyprland migration proposal (`docs/Hyprland.md` in the
  OpenRiot tree) which is blocked on packaging the Hyprland stack in ports and
  rewriting several thousand lines of X11 integration.
- **NixOS** already ships Hyprland, Quickshell, Wayland and the whole graphics
  stack, packaged and tested. Panacea already targets Hyprland.

So NixRiot keeps OpenRiot's taste, drops the OpenBSD-specific plumbing, and lets
Nix own installation and updates. The point is reproducibility: the desktop, the
installer and the update path are all the same pinned inputs.

## What it is

Three deliverables:

1. **A live image** built from nixpkgs' ISO image module on top of
   `installation-cd-base`. It is a minimal installer, not a desktop: tty1
   autologins as `nixos` and runs `nixriot-install`, the serial console gives a
   shell, and the image carries the flake inputs plus a curated pre-seed of the
   heaviest packages. Everything else comes from `cache.nixos.org` during the
   install, so **network is required**.
2. **A NixOS module** (`modules/nixriot.nix`) that declares the system: desktop,
   services, users, security, crypto, media, and the Panacea stack, behind
   `nixriot.*` options.
3. **A Home Manager module** that installs the Panacea trees, fish, Helix,
   Crush, XDG and GTK configuration, and the launcher overrides.

There is one flake on the machine. The installer writes the two files that are
specific to it (`hosts/installed/local.nix` and `hosts/installed/hardware-configuration.nix`)
and updates preserve exactly those. A separate per-machine flake was tried and
reverted: it broke installs and bought nothing.

## Relationship to the parents

| Project | Role in NixRiot |
|---|---|
| **NixOS 26.11** | Base system, package set, kernel, bootloader, installer tooling |
| **Panacea** | Desktop shell: Hyprland, Quickshell pill, wallpapers, keybindings, palette |
| **OpenRiot** | Feature list, visual language, fish/Helix/Crush defaults, crypto and media tooling, XDG layout |

Panacea's config trees are carried under `panacea/` and every deliberate
difference is recorded in `panacea/LOCAL-CHANGES.md`. Upstream is the reference,
not a build-time dependency.

NixRiot does not fork OpenRiot. It reuses the platform-neutral parts (fish,
Helix, fastfetch, wallpapers, cursors, icons) and reimplements the rest
declaratively.

## Architecture

```
NixRiot/
  flake.nix                  # nixosConfigurations.{nixriot,installed,live}, packages.{iso,installer}
  Makefile
  _config.yml, _layouts/, assets/   # Jekyll GitHub Pages site
  docs/Design.md, docs/Internals.md, docs/Panacea-Port.md
  modules/
    nixriot.nix              # options and top-level wiring
    update.nix               # nixriot-update, check timer, apply service, polkit rule
    desktop/
      panacea.nix            # Hyprland, Quickshell, portals, PAM, VPN
      theme.nix              # fonts, cursors, icons
      sddm.nix               # login theme (unused while autologin is on)
      plymouth.nix           # boot splash, built from the NixRiot artwork
    apps/
      shell.nix              # fish, starship, zoxide, ripgrep, btop
      editors.nix            # Helix, gnome-text-editor, Crush
      media.nix              # mpv, Lollypop, transmission
      office.nix             # zathura, Firefox, Thunar, AbiWord and Gnumeric (optional)
      games.nix              # optional curated game set
    crypto/                  # monero, bitcoin, wireguard, glyphriot
    security/                # hardening, backup
  home/
    panacea.nix              # Home Manager port of Panacea's install.sh
    fish.nix helix.nix crush.nix xdg.nix gtk.nix launcher.nix
  installer/default.nix      # the TUI installer
  iso/configuration.nix      # the live image
  panacea/                   # carried Panacea tree, themes, wallpapers
  hosts/
    example/                 # reference host config, the only hand-written hardware file
    installed/               # the machine's own files, written by the installer
```

### Installer flow

1. Build with `nix build .#iso`. `result/iso/NixRiot.iso` is the image, and the
   symlink makes it always the newest build.
2. Boot it. tty1 autologins as `nixos` and runs `nixriot-install`; the guard in
   `iso/configuration.nix` keeps it from running on any other getty.
3. The installer asks for a username, then an account password, then checks that
   `cache.nixos.org` answers. With no network it waits, offering `nmtui`, and
   will not touch a disk.
4. It takes a disk, requires `ERASE`, and asks for the LUKS passphrase twice
   (once to set, once to confirm; the same key file then unlocks the volume).
5. It partitions a 512M ESP labeled `BOOT` and the rest as LUKS2 `nixos`,
   formats, mounts, copies `/etc/nixriot` to `/mnt/etc/nixriot`, generates the
   hardware configuration into `hosts/installed/`, writes `local.nix`, and runs
   `nixos-install --root /mnt --flake /mnt/etc/nixriot#installed`.
6. It applies the account password with `chpasswd`, unmounts, and reboots into
   the installed system.

The whole run is teed to `/tmp/nixriot-install.log` in the guest, which is what
to read when an install looks stuck.

### Update flow

`/etc/nixriot` is a copy of the project; `hosts/installed/local.nix` is the
machine's. `nixriot-update` clones upstream, `rsync -a --delete` into
`/etc/nixriot` while excluding those two files, records the new revision in
`/etc/nixriot-revision`, and runs
`nixos-rebuild switch --flake /etc/nixriot#installed`. Details, including why the
revision is a real file rather than something derived from the flake, are in
`Internals.md`.

### Theming

`panacea/hypr/palette.conf` is the single palette: terracotta accent `#c65a47`,
background `#1b2b34`, foreground `#e5d1c5`. `hypr/scripts/palette.sh` spreads it
over fastfetch, foot (including the full 16-colour ANSI set), fish, btop, Zed,
neovim and Obsidian, and `switch_theme.sh` puts the wallpaper behind the login
screen. Firefox is deliberately not themed.

Because these files are rewritten at run time, Panacea's config trees are copied
into `~/.config` as writable files rather than Home Manager store symlinks.
`palette.sh`'s output is logged to `~/.cache/panacea/palette.log` so a failure is
visible instead of leaving stock colours in place.

### Testing

QEMU is the test harness. The recipe, the traps (`-display gtk` repaint under
Wayland, never putting a qcow2 in `/tmp`), and the serial-console trick for
reading the guest's install log are all in `Internals.md`.

## Feature parity

"Port" means reimplemented declaratively. "Reuse" means the existing config or
asset is carried.

| OpenRiot feature | NixRiot | Notes |
|---|---|---|
| i3 tiling | **Replaced** | Hyprland via Panacea |
| Polybar | **Replaced** | Panacea pill (Quickshell) |
| Rofi launcher | **Replaced** | Panacea launcher and launchpad, with a curated app list |
| Dunst notifications | **Replaced** | Panacea notification daemon |
| i3lock | **Replaced** | Panacea lock screen, via PAM `swaylock` |
| picom, feh, maim | **Replaced** | Hyprland compositor, hyprpaper, grim/slurp |
| picom rounded corners | **Replaced** | Hyprland `rounding = 8`, matching OpenRiot's radius |
| fish + starship prompt | **Reuse** | Home Manager |
| Helix | **Reuse** | nixpkgs `helix` |
| Crush | **Port** | nixpkgs `crush` |
| fastfetch + motd | **Reuse** | Home Manager |
| Bibata cursor, Kora icons | **Reuse** | Packaged assets |
| Nerd Fonts | **Reuse** | nixpkgs fonts |
| Wallpaper sets | **Own** | NixRiot set, `panacea/hypr/wallpaper` |
| Screenshots | **Port** | `grim`, `slurp`, `wl-clipboard` |
| Screen recording | **Port** | `wf-recorder` |
| Clipboard history | **Port** | `cliphist` |
| Music player | **Replaced** | Lollypop (MPRIS), because the pill reads MPRIS and mpd does not |
| Video | **Port** | mpv with `mpvScripts.mpris`, so the pill sees it |
| Monero GUI, Bitcoin Core | **Port** | nixpkgs, opt-in |
| WireGuard | **Port** | `networking.wireguard` |
| Mullvad | **Port** | daemon plus the GUI |
| Transmission | **Port** | nixpkgs `transmission_4-gtk` |
| Proton Drive sync | **Port** | `rclone` |
| Signal (gurk) | **Port** | nixpkgs `gurk-rs`, with a launcher entry |
| AbiWord, Gnumeric, Firefox | **Port** | nixpkgs |
| Backup and restore | **Port** | `restic` |
| Disk manager | **Port** | `gnome-disk-utility` or `gparted` |
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
| Xenodm, Xenocara, X11 hardening | The Wayland stack replaces X11 |
| OpenBSD version tracking | NixOS channels and flake locks replace it |
| `openriot` Go installer paths | Nix modules replace imperative installs |
| GRUB and its theme | NixRiot boots with systemd-boot |
| 3D printing (PrusaSlicer, OrcaSlicer) | Cut; not part of the desktop |
| mpd and rmpc | No MPRIS, so the pill and the media keys could not see them |
| yt-dlp | Pulled in a 139 MB Deno runtime for a feature nothing needed |
| Zed | Available (`zed-editor`) but not installed; Helix and Crush are the defaults |
| SDDM theme | Autologin means there is no greeter to theme |
| QtWebEngine | 419 MB of Chromium for one lazy chat page in the pill |

## Open work

Ordered by priority. The live list is in `Internals.md` and `AGENTS.md`.

1. **Install on real hardware.** Nothing has been installed on a physical
   machine yet.
2. **Confirm the fish-completions fix.** `programs.fish.generateCompletions = false`
   is decided but not yet applied; it removes hundreds of local
   `runCommandLocal` builds from every install.
3. **gvfs MTP** for phones, untested.
4. **A binary cache** for the flake's own outputs, so installs stop building our
   derivations (the trimmed `linux-firmware`, cursors, fonts, splash).
5. **Offline installs**, if they are wanted at all. Today the image is a
   netinstall by design, because GitHub caps release assets at 2 GiB.

## Milestones

| Phase | Deliverable | Exit criteria | State |
|---|---|---|---|
| 0 | Flake skeleton | `nix flake check` passes, system builds | done |
| 1 | Panacea Home Manager module | Hyprland session starts, pill runs, keybindings work | verified in QEMU |
| 2 | Theme, assets, splash | Fonts, cursors, icons, wallpapers, Plymouth | verified in QEMU |
| 3 | OpenRiot app modules | fish, Helix, Crush, media, crypto, security | verified in QEMU |
| 4 | ISO and installer | ISO boots, installs, first boot reaches the desktop | verified in QEMU, not on hardware |
| 5 | Parity audit | Every parity row verified or explicitly cut | pending |
| 6 | Release | Tagged flake, checksums, install notes | pending |

## Risks

- **The ISO carries the repo.** Any repo change needs an ISO rebuild before an
  installed system can see it.
- **Panacea tracks upstream closely.** Its QML needs `QtMultimedia` on the QML
  import path or the shell will not load, and its scripts assume Arch paths in
  places.
- **Distribution size.** The image is 1.97 GiB against GitHub's 2 GiB per-asset
  limit. The pre-seed list is what keeps it there, and it is a size decision,
  not a speed one.
- **UEFI only.** systemd-boot, Secure Update off, no BIOS.
- **The installer builds our own derivations**, because they are in no binary
  cache. That is the slow part of an install.
- **`hardware.firmware` is `mkForce`d** to a trimmed list; anything that adds
  firmware must be appended there.
- **Cosmetic `buildEnv` collisions** exist for `gvfs` and `bitcoind`.

## Non-goals

- Replacing Panacea upstream. NixRiot packages it, it does not fork it.
- Replacing OpenRiot on OpenBSD. NixRiot is the Linux sibling, not a port.
- NVIDIA, ARM, or Secure Boot.
- Being a general-purpose distribution. It is one desktop, deliberately.
