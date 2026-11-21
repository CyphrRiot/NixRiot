<div align="center">

![NixRiot](docs/img/banner.webp)

![Status](https://img.shields.io/badge/status-early_release-9a2eef?labelColor=1b2b34)
![Version](https://img.shields.io/badge/version-1.9-9a2eef?labelColor=1b2b34)
![Platform](https://img.shields.io/badge/platform-NixOS-9a2eef?logo=nixos&logoColor=white&labelColor=1b2b34)
![Shell](https://img.shields.io/badge/shell-Hyprland-9a2eef?logo=hyprland&logoColor=9a2eef&labelColor=1b2b34)
![UI](https://img.shields.io/badge/UI-Quickshell-9a2eef?labelColor=1b2b34)
![Last Commit](https://img.shields.io/github/last-commit/CyphrRiot/NixRiot?color=9a2eef&labelColor=1b2b34)
![Code Size](https://img.shields.io/github/languages/code-size/CyphrRiot/NixRiot?color=9a2eef&labelColor=1b2b34)

![Code](https://img.shields.io/badge/human-coded-9a2eef?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiNmZmZmZmYiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1wZXJzb24tc3RhbmRpbmctaWNvbiBsdWNpZGUtcGVyc29uLXN0YW5kaW5nIj48Y2lyY2xlIGN4PSIxMiIgY3k9IjUiIHI9IjEiLz48cGF0aCBkPSJtOSAyMCAzLTYgMyA2Ii8+PHBhdGggZD0ibTYgOCA2IDIgNi0yIi8+PHBhdGggZD0iTTEyIDEwdjQiLz48L3N2Zz4=&logoColor=9a2eef&labelColor=1b2b34)
![Language](https://img.shields.io/badge/language-Nix-9a2eef?logo=nixos&logoColor=9a2eef&labelColor=1b2b34)
![Language](https://img.shields.io/badge/language-QML-9a2eef?logo=qt&logoColor=41CD52&labelColor=1b2b34)
[![Donate BTC](https://img.shields.io/badge/Donate-Bitcoin-F7931A?logo=bitcoin&logoColor=white&labelColor=1b2b34)](#donations)

</div>

## Status of NixRiot

**Early release.** It installs over the network with LUKS and boots to the
NixRiot desktop: the pill, the launcher, its settings, the terminal. It is
running on real hardware now, a Bluetooth keyboard included.

Still unverified: the password vault, the media keys, and the pill's media
capsule. The hardware notes below are what has actually been checked.

![The NixRiot desktop: the pill, its settings pages, and a terminal](docs/img/desktop-demo.gif)

## Philosophy of NixRiot

NixRiot is a small, fast, reproducible desktop, assembled from things we learned
the hard way.

ArchRiot was the first pass: Arch, an installer, and hand-maintained dotfiles. It
taught us what the desktop should feel like. Omarchy then covered much of that
ground, so we stopped rather than duplicate it. What we could not fix on Arch was
trust: the AUR means running code from strangers, and that is not a defensible
default for a desktop you have to keep patched. OpenBSD came next and remains the
Unix we trust most, but modern hardware there is a permanent fight: network
cards, GPUs, Bluetooth, and the rest of what a desktop needs.

NixRiot takes all of that and puts it on a foundation that can be trusted and
reproduced. One flake. Packages from a pinned nixpkgs. An installer that builds
the same system it was built from.

A reproducible NixOS desktop with the [Panacea](https://github.com/EnsixD/Panacea)
shell and the parts of [OpenRiot](https://OpenRiot.org) that
make sense on Linux. One flake builds the installer image and the installed
system, so both stay in step.

The reasoning behind it is in the [article on X](https://x.com/CyphrRiot/status/2123604405975134647).

## Screenshots

The desktop, the launcher and the power menu:

![The NixRiot desktop, with the pill collapsed at the top](docs/img/desktop.webp)

![The launcher, searching the curated application list](docs/img/launcher.webp)

![The power menu](docs/img/power.webp)

Read [docs/Design.md](docs/Design.md) for the reasoning, architecture, and
roadmap. This file is the manual.

## Navigate this guide

- [The usual free software warning](#the-usual-free-software-warning)
- [What you get](#what-you-get)
- [Download](#download)
- [Requirements](#requirements)
- [Supported hardware](#supported-hardware)
- [Install](#install)
- [First boot](#first-boot)
- [Keybindings](#keybindings)
- [What is installed](#what-is-installed)
- [Shell aliases and quick reference](#shell-aliases-and-quick-reference)
- [Control center](#control-center)
- [Wallpapers](#wallpapers)
- [Night light](#night-light)
- [Weather](#weather)
- [Blockchain](#blockchain)
- [VPN](#vpn)
- [Browser and moving from OpenRiot](#browser-and-moving-from-openriot)
- [Games](#games)
- [Updating](#updating)
- [Advanced: build your own image](#advanced-build-your-own-image)
- [Troubleshooting](#troubleshooting)
- [Donations](#donations)
- [Licence and credits](#licence-and-credits)

---

## The usual free software warning

This installer **erases the disk you point it at**. It partitions, encrypts, and
formats without asking twice. Back up anything you care about first.

NixRiot ships no wallet files and no secrets. You own those.

---

## What you get

- **Hyprland** with the Panacea pill (Quickshell): launcher, launchpad,
  overview, clipboard, notifications, settings, power menu, lock screen.
- **fish** with a prompt of its own (hostname, directory, git branch, exit
  status), plus the OpenRiot aliases and functions.
- **Helix** (the default editor), Crush, and a plain text editor.
- **Firefox**, zathura, and LibreOffice when `nixriot.office` is on. To use it,
  set `nixriot.office = true;` in `/etc/nixriot/hosts/installed/local.nix` and
  run `rebuild`.
- **Media**: mpv, Lollypop, optional Transmission.
- **Signal** Desktop, with `gurk` for the terminal, which is the only Signal
  OpenRiot could have: OpenBSD has no desktop client.
- **Crypto** (opt-in): Monero GUI, Bitcoin Core, WireGuard.
- **Mullvad VPN**: the daemon and the desktop app are installed and enabled by
  default, with the GUI in the app launcher and the `mullvad` command line.
- **Security**: firewall, SSH hardening, sysctl hardening, MAC randomization,
  `restic` and `rclone` for backups.
- The **NixRiot wallpaper set** (29 WebP images, `00.webp` through `28.webp`).
- A **night light** for the screen, off until you switch it on (`SUPER + N`).
- Full-disk encryption (LUKS2) on the root volume, chosen during install.

---

## Download

Grab the latest image and write it to a USB stick. No build tools required.

- **Download page:** [github.com/CyphrRiot/NixRiot/releases/latest](https://github.com/CyphrRiot/NixRiot/releases/latest)
- **Image:** `NixRiot.iso` (about 2 GB)

```sh
sudo dd if=NixRiot.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

It is a network installer: it carries the installer, the project and the biggest
parts of the desktop, and downloads the rest while it installs. It needs an
internet connection.

Prefer to build the image yourself? See Advanced, at the end of this file.

---

## Requirements

- x86_64 machine that boots UEFI.
- A USB stick of at least 4 GB.
- A target disk that can be erased.
- An internet connection during install.

Installing does not require Nix on your machine: the image provides it. You only
need Nix, with flakes enabled and about 40 GB free, if you build the image
yourself.

---

## Supported hardware

NixRiot targets x86_64 machines with an Intel or AMD GPU. Hyprland and
Quickshell need working OpenGL under Mesa, and Mesa is what the open-source
Intel and AMD drivers use.

- **GPU:** Intel (i915 or Xe) and AMD (amdgpu), integrated or discrete. NVIDIA
  needs proprietary drivers and is not supported or tested.
- **CPU:** Intel and AMD x86_64. ARM is not built.
- **Drivers and firmware:** `hardware.graphics` is enabled, and the live image
  turns on all hardware, so GPU, Wi-Fi and Bluetooth firmware load on their own.
  Installed systems ship a deliberately trimmed `linux-firmware`
  (`modules/nixriot.nix`): every x86 Wi-Fi, Bluetooth, GPU and audio family is
  kept, including NVIDIA, while datacentre NICs and the Qualcomm `qcom` blobs
  are dropped to save space. An unusual network card may need it added back.
- **Boot:** UEFI only, via systemd-boot. Secure Boot must be off.
- **Out of scope:** NVIDIA, ARM, and Secure Boot. Fingerprint readers are off by
  default but supported through `fprintd`; see the note below.
- **Installed systems:** the installer generates the hardware configuration for
  the machine it is run on, so the disk and firmware modules are correct.

### Fingerprint reader

Off by default. To try it, enable the daemon **without** touching PAM first, in
`/etc/nixriot/hosts/installed/local.nix`, beside `nixriotUser` and
`nixriot.hostName`:

```nix
nixriot.fingerprint.enable = true;
```

Rebuild, then run `fprintd-enroll` and `fprintd-verify` as your user. Only if
those succeed, add fingerprint auth to login, sudo and polkit:

```nix
nixriot.fingerprint.enable = true;
nixriot.fingerprint.pam = true;
```

If the reader needs Touch OEM Drivers, set `nixriot.fingerprint.tod.enable =
true` and point `nixriot.fingerprint.tod.driver` at the matching package (for
example `pkgs.libfprint-2-tod1-goodix`). Support comes from `libfprint`; a
reader it does not know cannot be made to work.

One thing to expect once PAM is on: with the lid shut, the reader is out of
reach, and PAM asks for a finger before falling back to the password. NixRiot
does not gate on the lid yet; that, and detecting the reader automatically
instead of leaving it off, is planned.

---

## Install

**A network connection is required.** The installer builds the target system from
the flake and fetches the rest from `cache.nixos.org`, and it will not touch a
disk until that answers.

1. Boot the USB stick (disable Secure Boot first if the firmware refuses it).
2. It comes up on a text console, logs in as `nixos`, and starts the installer by
   itself.
3. It asks for a username, a hostname for the machine, then a password for that
   user. The username uses lowercase letters, digits, underscore or hyphen, and
   does not start with a digit or underscore. The hostname defaults to
   `nixriot` if you press Enter, and takes lowercase letters, digits and
   hyphens.
4. It checks that it can reach `cache.nixos.org`, and will not touch a disk until
   it can. If the check fails it offers `retry`, `w` to run `nmtui`, or `skip`;
   `skip` is for a machine whose store already holds everything, not for a broken
   connection.
5. It lists the disks it can see. Type the target disk, for example
   `/dev/nvme0n1`.
6. Type `ERASE` to confirm. This is the point of no return.
7. Enter the LUKS passphrase twice (once to set it, once to confirm). It is
   reused to unlock the new volume, so there is no third prompt. You will type
   this at every boot, so pick something you can remember and write it down
   somewhere safe.
8. It partitions (512M ESP labeled `BOOT`, the rest as an encrypted `nixos`
   volume), formats, mounts, and runs `nixos-install`.
9. When `nixos-install` finishes, it unmounts and reboots into the installed
   system. Remove the USB stick.

The install builds the target system from the flake and downloads it from
`cache.nixos.org`, so it needs a network connection. Everything is logged to
`/tmp/nixriot-install.log`.

---

## First boot

The boot splash appears, then the LUKS passphrase prompt, then the session
starts on its own: NixRiot logs the desktop user in automatically, so the login
screen is skipped. The lock screen (`SUPER + L`) is what protects the machine,
and if you log out you land on the themed login screen. `sudo` asks for the
password you set during install.

NixRiot ships no default user or password.

To change or reset your password, log in and run:

```sh
passwd
```

To rename the machine, set `nixriot.hostName` in
`/etc/nixriot/hosts/installed/local.nix` and run `rebuild`. `/etc/hostname` is
generated by NixOS and is read-only; edits there do nothing.

---

## Keybindings

`SUPER` is the modifier. The map lives in `panacea/hypr/lua/keybindings.lua`,
with the matching defaults in `panacea/shell.qml`. Rebind anything from the
settings panel (`SUPER + I`), which writes overrides that survive updates.

### Shell and launcher

| Keys | Action |
|---|---|
| `SUPER + D` or `SUPER + A` | Launcher |
| `SUPER + G` | Launchpad |
| `SUPER + Tab` | Overview |
| `SUPER + /` | Shortcut list |
| `SUPER + I` | Settings |
| `SUPER + Z` | Control center |
| `SUPER + SHIFT + N` | Notifications |
| `SUPER + SHIFT + V` | Clipboard history |
| `SUPER + Escape` | Power menu |
| `SUPER + SHIFT + P` | Password vault |

### Apps and windows

`SUPER + F` opens Panacea Files, the only file manager: folders opened from
another application land in the same view.

| Keys | Action |
|---|---|
| `SUPER + Return` | Terminal (foot) |
| `SUPER + T` | btop, process viewer |
| `SUPER + B` | Firefox |
| `SUPER + F` | Panacea Files |
| `SUPER + E` | Panacea Files (alternate) |
| `SUPER + SHIFT + E` | Yazi in the terminal |
| `SUPER + O` | Text editor |
| `SUPER + C` | Crush |
| `SUPER + SHIFT + K` | Music player (Lollypop) |
| `SUPER + Q` | Close window |
| `SUPER + W` | Toggle floating |
| `SUPER + SHIFT + Space` | Float, resize, center |
| `SUPER + J` | Toggle split |
| `SUPER + SHIFT + F` | Fullscreen |
| `SUPER + L` | Lock |
| `SUPER + SHIFT + T` or `SUPER + SHIFT + D` | Wallpapers |
| `SUPER + SHIFT + M` | Exit Hyprland |
| `SUPER + SHIFT + S` or `Print` | Screenshot (region) |
| `SUPER + P` | Screen recording |
| `SUPER + SHIFT + F12` | Screen off |
| `SUPER + N` | Night light on or off |
| `SUPER + M` or `XF86Mail` | Proton Mail |
| `SUPER + X` | X (compose with `SUPER + SHIFT + X`) |

### Workspaces and movement

| Keys | Action |
|---|---|
| `SUPER + 1..0` | Focus workspace |
| `SUPER + SHIFT + 1..0` | Move window to workspace |
| `SUPER + Space` | First empty workspace |
| `SUPER + S` | Special workspace (`magic`) |
| `SUPER + arrows` | Focus window |
| `SUPER + SHIFT + arrows` | Move window |
| `ALT + arrows` | Resize window |
| `SUPER + SHIFT + A` | Pack workspaces |
| `SUPER + mouse wheel` | Next or previous workspace |
| `SUPER + drag` | Move window |
| `SUPER + right drag` | Resize window |

### Media and hardware

| Keys | Action |
|---|---|
| `XF86Audio*` | Volume, mute, play/pause, tracks |
| `XF86MonBrightness*` | Brightness |
| Right Alt (hold) | Voice to text |

Closing the lid locks the screen and suspends, unless a second display is
attached: a closed lid with an external monitor is a machine still in use, so it
stays awake. The lock comes from hypridle's `before_sleep_cmd`. Fifteen minutes
with no input locks the screen too.

---

## What is installed

Everything is declared in `modules/`. The example and installed hosts enable the
full set.

| Module | Packages |
|---|---|
| `apps/shell.nix` | fish, zoxide, ripgrep, fd, fzf, btop, fastfetch, lsd, bat, pv, jq, signal-desktop, gurk-rs |
| `apps/editors.nix` | helix, gnome-text-editor, crush, git |
| `apps/media.nix` | mpv, lollypop, ffmpeg, ffmpegthumbnailer, cava, transmission (optional) |
| `apps/office.nix` | zathura, firefox, file-roller, libreoffice (optional) |
| `desktop/panacea.nix` | hyprland, quickshell, hyprpaper, hyprsunset, hypridle, foot, grim, slurp, wl-clipboard, cliphist, wf-recorder, yazi, swappy, mpvpaper, and the rest of the shell's runtime (tesseract with `nixriot.ocr`) |
| `desktop/theme.nix` | JetBrains Mono Nerd Font, Material Design icons, Noto fonts, Bibata cursors, Kora icons |
| `crypto/*` | monero-gui, bitcoin and bitcoind, glyphriot, wireguard-tools |
| `security/*` | restic, rclone, firewall, SSH hardening, sysctl hardening |
| `apps/games.nix` | optional, off by default |

---

## Shell aliases and quick reference

These come from `home/fish.nix`, which is OpenRiot's fish configuration adapted
for NixOS.

| Command | Does |
|---|---|
| `vim`, `vi` | Helix (`hx`) |
| `helix` | `hx` |
| `signal` | Signal TUI (`gurk`) |
| `ls`, `ll`, `la` | `lsd`, `lsd -l`, `lsd -la` |
| `music` | `lollypop` |
| `rebuild` | `sudo nixos-rebuild switch --flake /etc/nixriot#installed` |
| `more` | `more -e` |
| `dum` | top 10 largest items in the current directory |
| `!!` | expands to the previous command |
| `Ctrl+O` | inserts the previous command |

The prompt shows hostname, working directory, git branch, and a non-zero exit
code, with the Linux glyph in the accent colour driven by the Panacea palette.

## Control center

Panacea's settings live in the pill. `SUPER + I` opens them; every section is
also reachable from the pill's expanded island. `SUPER + Z` opens the control
center (Wi-Fi, Bluetooth, audio, power profile, and **Stay awake**, which stops
the screen blanking, the machine sleeping and lid-close suspend until you turn it
off). `SUPER + /` lists every current binding.

---

## Wallpapers

The NixRiot set (29 WebP images, `00.webp` through `28.webp`) ships in
`panacea/hypr/wallpaper/`, default `27.webp`. Change the wallpaper from
Settings > Appearance > Wallpapers, or with `SUPER + SHIFT + T` or
`SUPER + SHIFT + D`. The manifest is
`panacea/hypr/wallpaper/WALLPAPERS.md`.

Adding an image means adding a licence entry to that manifest. Live video
wallpapers are not shipped.

---

## Night light

Off by default. `SUPER + N` switches it, or **Settings → Display → Night light**
in the pill, where the temperature sits between 2500K and 6500K and an optional
schedule turns it on in the evening and off in the morning. 4000K is the default
when it comes on, the same temperature OpenRiot used.

The filter is applied by `hyprsunset`, so it is part of what the compositor
draws: screenshots and recordings carry it. The pill shows a moon when it is on.

---

## Weather

The weather card and the island's optional weather row read OpenWeatherMap.
Create a free API key at [openweathermap.org](https://openweathermap.org/api),
then open **Settings (`SUPER + I`) → Appearance → Weather** and fill in the key
and a city (a name like `Portland`, or a numeric ZIP). Choose metric or imperial
there.

The key lives in `~/.config/panacea/settings.json`, so it survives updates and
is never shipped in the image. Without a key and a city the card stays empty by
design.

---

## Blockchain

Add the `nixriot` stanza **inside** `/etc/nixriot/hosts/installed/local.nix`,
next to your username. The file holds both, and an update preserves it:

```nix
{
  nixriotUser = "riot";
  nixriot = {
    crypto.monero = true;
    crypto.bitcoin = true;
    crypto.glyphriot = true;
  };
}
```

Monero GUI and Bitcoin Core come from nixpkgs. `crypto.glyphriot` installs
[GlyphRiot](https://github.com/CyphrRiot/glyphriot), a seed-phrase glyph tool
for self-custody, built from source and pinned to a commit. WireGuard is
configured with `nixriot.wireguard.enable = true;` in the same stanza. Wallet
files and keys, seed phrases included, are yours to create and back up; the
flake never ships them.

---

## VPN

Mullvad VPN is installed and enabled by default: the daemon starts at boot and
the desktop app is in the app launcher. The `mullvad` command line works too:

```sh
sudo mullvad account login <your-16-digit-account>
sudo mullvad relay set location us nyc
sudo mullvad connect
mullvad status
```

The pill's VPN panel is a status readout: it reports whether a tunnel is up (it
detects Mullvad's `wg0-mullvad` interface), but connecting and picking a server
happen in the app.

For a WireGuard config (the OpenRiot workflow), set
`nixriot.wireguard.enable = true;` in
`/etc/nixriot/hosts/installed/local.nix` and put your config in
`/etc/wireguard/wg0.conf`. The Panacea VPN panel detects `wg0` and reports the
tunnel state.

---

## Browser and moving from OpenRiot

The default browser is **Firefox**, which is also OpenRiot's. Nothing about
your browsing setup has to change.

Moving from OpenRiot:

- **Bookmarks**: in Firefox, `Ctrl+Shift+O`, then Import and Backup, Export
  Bookmarks to JSON. On the new machine, import the same file.
- **Passwords**: in Firefox, `about:logins`, then the menu at the top right,
  Export Logins. Import it the same way on the new machine. Delete the export
  file afterwards; it is plain text.
- **Default browser**: NixRiot sets Firefox for `http`, `https`, and
  `text/html` in `home/xdg.nix`. To change it, edit
  `xdg.mimeApps.defaultApplications` there.

Brave, Chromium, and other browsers are not installed by default.

---

## Games

Off by default. To install the curated set, add `nixriot.games = true;` to the
`nixriot` stanza in `/etc/nixriot/hosts/installed/local.nix`. It pulls supertux, openttd,
cataclysm-dda, endless-sky, angband, and brogue-ce. It is deliberately a small
subset of OpenRiot's list; several OpenRiot games are no longer in nixpkgs.

---

## Updating

`/etc/nixriot` is a copy of the project, and
`/etc/nixriot/hosts/installed/local.nix` is yours. An update replaces the
project and keeps the two machine files (`local.nix` and
`hardware-configuration.nix`).

From the pill: **Settings → System → Update**. On the command line:

```sh
sudo nixriot-update apply
```

That clones the project from GitHub, replaces `/etc/nixriot` with it, and
rebuilds. A timer runs `nixriot-update check` every four hours and writes the
result to `/var/lib/nixriot/status.json`, which is what the pill reads.

To rebuild without fetching anything, run the same `rebuild` alias:

```sh
rebuild
```

`nix flake update` there moves the packages forward, but it only edits the copy:
the next `nixriot-update apply` replaces the whole tree, `flake.lock` included,
so the change is discarded.

Package versions come from the flake's `nixpkgs` input, not from `/etc/nixriot`.
To move them for everyone, run `nix flake update nixpkgs` in a clone of this
repository, commit the new `flake.lock`, and release; installed machines pick it
up with the next update, run from **Settings → System → Update** or with
`sudo nixriot-update apply`.

Never install or upgrade system packages with `nix profile` or `nix-env`. They
land outside the flake, survive updates unpredictably, and cannot be reproduced.

Panacea's own updater is replaced by an adapter that drives `nixriot-update`;
the upstream one rewrote the config tree and would fight the flake.

---

## Advanced: build your own image

To build the image yourself, on any machine running Nix with flakes enabled:

```sh
git clone git@github.com:CyphrRiot/NixRiot.git
cd NixRiot
nix build .#iso
```

The image lands at `result/iso/NixRiot.iso`. It is a hybrid image, so `dd` it to
a USB stick as in Download. Building needs about 40 GB of free space and network
access for the first `nix flake lock`.

`make release` and `make bump` need the dev shell: run `nix develop` first, then
`make release`.

---

## Troubleshooting

Anything not covered here belongs in a [GitHub
issue](https://github.com/CyphrRiot/NixRiot/issues). If it came from an install,
attach the log.

- **The install failed partway.** Re-run `sudo nixriot-install`; it wipes and
  starts over.
- **No network during install.** The installer refuses to touch a disk until
  `cache.nixos.org` answers. Press `w` at the prompt to run `nmtui`.
- **The install failed and you want to report it.** The entire run is in
  `/tmp/nixriot-install.log` inside the live system. Send it with:

  ```sh
  curl --data-binary @/tmp/nixriot-install.log https://paste.rs
  ```

  That prints a URL on stdout; put it in the issue.

- **The time zone cannot be changed from Panacea.** The pill runs
  `pkexec timedatectl set-timezone`. On a generation that still manages
  `/etc/localtime`, that path points into the read-only Nix store and
  `timedatectl` fails with `Read-only file system`. NixRiot sets
  `time.timeZone = null` so `timedatectl` owns the file, and a polkit rule
  allows `wheel` to run `timedatectl`. On an older generation, set it by hand:
  `sudo ln -sfn /etc/zoneinfo/Region/City /etc/localtime`. A rebuild from a tree
  that still sets `time.timeZone = "UTC"` will undo the change.

---

<a id="donations"></a>

## Donations

NixRiot was built by one person. If it saved you time, consider donating
(in Bitcoin):

`bc1q77vh5x2ujgzjesc8s877hsvuzgx8z8m20flww8`

---

## Licence and credits

NixRiot's own code is MIT. Panacea is MIT. OpenRiot is MIT. Wallpapers, fonts,
and bundled assets keep their original authors' terms.

- [NixOS](https://nixos.org)
- [Panacea](https://github.com/EnsixD/Panacea)
- [OpenRiot](https://github.com/CyphrRiot/OpenRiot)
