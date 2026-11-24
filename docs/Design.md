# NixRiot Design

Why NixRiot exists, and what it kept from the desktops before it. The manual is
`../README.md`; the durable internals (decisions, installer contract, update
mechanics, verified package facts, known risks) are in `Internals.md`.

Status: living document. Last updated 2026-11-23.

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
  OpenRiot tree), blocked on packaging the Hyprland stack in ports and rewriting
  several thousand lines of X11 integration.
- **NixOS** already ships Hyprland, Quickshell, Wayland and the whole graphics
  stack, packaged and tested. Panacea already targets Hyprland.

So NixRiot keeps OpenRiot's taste, drops the OpenBSD-specific plumbing, and lets
Nix own installation and updates. The point is reproducibility: the desktop, the
installer and the update path are all the same pinned inputs.

## Relationship to the parents

| Project | Role in NixRiot |
|---|---|
| **NixOS** (unstable, pinned in `flake.lock`) | Base system, package set, kernel, bootloader, installer tooling |
| **Panacea** | Desktop shell: Hyprland, Quickshell pill, wallpapers, keybindings, palette |
| **OpenRiot** | Feature list, visual language, fish/Helix/Crush defaults, crypto and media tooling, XDG layout |

Panacea's config trees are carried under `panacea/` and every deliberate
difference is recorded in `panacea/LOCAL-CHANGES.md`. Upstream is the reference,
not a build-time dependency.

NixRiot does not fork OpenRiot. It reuses the platform-neutral parts (fish,
Helix, fastfetch, wallpapers, cursors, icons) and reimplements the rest
declaratively.

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
| fish + prompt | **Port** | Own `fish_prompt` in `home/fish.nix`, coloured from the palette |
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
| Proton Drive sync | **Port** | `rclone`, configured by hand |
| Signal (gurk) | **Port** | nixpkgs `gurk-rs`, with a launcher entry |
| LibreOffice, Firefox | **Port** | nixpkgs |
| Backup and restore | **Port** | `backup.sh` mirrors the home folder with `rsync`; `restic` and `rclone` are also installed |
| SSH hardening | **Port** | NixOS options |
| XDG user directories | **Port** | Home Manager |
| Crypto config (`crypto.toml`) | **Replaced** | `nixriot.crypto.*` options in `local.nix` |
| Control center | **Replaced** | Panacea settings and quick settings |
| Games bundle | **Optional** | Curated subset, opt-in module |
| Night light | **Port** | `hyprsunset`, off by default, 4000K and `SUPER+N` as OpenRiot used |
| Idle lock | **Port** | `hypridle`: display off at 10 minutes, lock at 15, suspend at 20 |

NixRiot also has things OpenRiot did not: a password vault unlocked through PAM,
signed release updates with the update pill, package installs from Settings, a
what's-new window after a release, and an installer that builds the target
system from the same flake.

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

## Non-goals

- Replacing Panacea upstream. NixRiot packages it, it does not fork it.
- Replacing OpenRiot on OpenBSD. NixRiot is the Linux sibling, not a port.
- NVIDIA, ARM, or Secure Boot.
- Being a general-purpose distribution. It is one desktop, deliberately.
