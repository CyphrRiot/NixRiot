# NixRiot

A reproducible NixOS desktop with the [Panacea](https://github.com/EnsixD/Panacea)
shell and the parts of [OpenRiot](https://github.com/CyphrRiot/OpenRiot) that
make sense on Linux. One flake builds the installer image and the installed
system, so both stay in step.

Status: **pre-release**. The flake evaluates and the ISO builds. It has not been
booted on real hardware yet, so treat everything below as untested until you
have installed it once.

Read [docs/Design.md](docs/Design.md) for the reasoning, architecture, and
roadmap. This file is the manual.

## Navigate this guide

- [The usual free software warning](#the-usual-free-software-warning)
- [What you get](#what-you-get)
- [Download](#download)
- [Requirements](#requirements)
- [Install](#install)
- [First boot](#first-boot)
- [Keybindings](#keybindings)
- [What is installed](#what-is-installed)
- [Shell aliases and quick reference](#shell-aliases-and-quick-reference)
- [Control center](#control-center)
- [Wallpapers](#wallpapers)
- [Blockchain](#blockchain)
- [Browser and moving from OpenRiot](#browser-and-moving-from-openriot)
- [Games](#games)
- [Updating](#updating)
- [Advanced: build your own image](#advanced-build-your-own-image)
- [Troubleshooting](#troubleshooting)
- [Licence and credits](#licence-and-credits)

---

## The usual free software warning

This installer **erases the disk you point it at**. It partitions, encrypts, and
formats without asking twice. Back up anything you care about first.

NixRiot ships no wallet files, no secrets, and no `crypto.toml`. You own those.

---

## What you get

- **Hyprland** with the Panacea pill (Quickshell): launcher, launchpad,
  overview, clipboard, notifications, settings, power menu, lock screen.
- **fish** with starship, plus the OpenRiot aliases and functions.
- **Helix**, Zed, Kate, and Crush.
- **Firefox**, LibreOffice, Thunderbird, zathura, Thunar.
- **Media**: mpv, mpd with rmpc, yt-dlp, optional Transmission.
- **Crypto**: Monero GUI, Bitcoin Core, WireGuard.
- **Security**: firewall, SSH hardening, sysctl hardening, MAC randomization,
  `restic` and `rclone` for backups.
- The **NixRiot wallpaper set** (13 WebP images).
- Full-disk encryption (LUKS2) on the root volume, chosen during install.

---

## Download

Grab the latest image and write it to a USB stick. No build tools required.

- **Download page:** https://github.com/CyphrRiot/NixRiot/releases/latest
- **Image:** `nixriot-x86_64.iso` (about 2.5 GB)

```sh
sudo dd if=nixriot-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

**No release yet?** Two fallbacks:

- Boot a stock NixOS graphical ISO and install over it:

  ```sh
  sudo nix run github:CyphrRiot/NixRiot#installer
  ```

- Or build the image yourself. See Advanced, at the end of this file.

---

## Requirements

- x86_64 machine that boots modern UEFI.
- A USB stick of at least 6 GB.
- A target disk that can be erased.
- Network during install, unless you are using an offline image.

You do not need to know Nix to install NixRiot. You need Nix, with flakes
enabled and about 40 GB free, only if you build the image yourself.

---

## Install

1. Boot the USB stick (disable Secure Boot first if the firmware refuses it).
2. You land in the NixOS live session with the NixRiot repo at `/etc/nixriot`.
3. Open a terminal and run:

   ```sh
   sudo nixriot-install
   ```

4. The command lists the disks it can see. Type the target disk, for example
   `/dev/nvme0n1`.
5. Type `ERASE` to confirm. This is the point of no return.
6. Enter the LUKS passphrase when `cryptsetup` prompts. You will type this at
   every boot, so pick something you can remember and write it down somewhere
   safe.
7. It partitions (512M ESP labeled `BOOT`, the rest as an encrypted `nixos`
   volume), formats, mounts, and runs `nixos-install`.
8. When `nixos-install` finishes, the installer asks you to set a password for
   the `riot` user. Choose one; there is no default.
9. Reboot and remove the USB stick.

The install builds the target system from the flake, so it needs network the
first time. Offline installs are on the roadmap, not shipped yet.

---

## First boot

The disk passphrase prompt comes first, then SDDM. Log in as **`riot`** with the
password you set at the end of the install. `sudo` asks for the same password.
NixRiot ships no default password.

If you skipped that step, set one from the installer or a TTY:

```sh
passwd
```

---

## Keybindings

`SUPER` is the modifier. Panacea's map lives in
`vendor/panacea/hypr/lua/keybindings.lua`. NixRiot adds an OpenRiot-compatible
overlay in `vendor/panacea/hypr/custom/keybindings.lua` and the matching
`keybinds.conf`. Rebind anything from the settings panel (`SUPER + I`), which
writes overrides that survive updates.

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
| `SUPER + V` or `SUPER + SHIFT + V` | Clipboard history |
| `SUPER + Escape` or `CTRL + ALT + Delete` | Power menu |
| `SUPER + SHIFT + P` | Password vault |

### Apps and windows

| Keys | Action |
|---|---|
| `SUPER + Return` | Terminal (foot) |
| `SUPER + T` | btop, process viewer |
| `SUPER + B` | Firefox |
| `SUPER + F` | Thunar (file manager) |
| `SUPER + E` | Panacea Files view |
| `SUPER + SHIFT + E` | Yazi in the terminal |
| `SUPER + O` | Text editor |
| `SUPER + C` | Crush |
| `SUPER + SHIFT + K` | Music player (rmpc) |
| `SUPER + Q` | Close window |
| `SUPER + W` | Toggle floating |
| `SUPER + SHIFT + Space` | Float, resize, center |
| `SUPER + J` | Toggle split |
| `SUPER + SHIFT + F` | Fullscreen |
| `SUPER + L` | Lock |
| `SUPER + SHIFT + T` | Switch theme |
| `SUPER + SHIFT + M` | Exit Hyprland |
| `SUPER + SHIFT + S` or `Print` | Screenshot (region) |
| `SUPER + P` | Screen recording |
| `SUPER + SHIFT + F12` | Screen off |

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

Closing the lid locks the screen.

---

## What is installed

Everything is declared in `modules/`. The example and installed hosts enable the
full set.

| Module | Packages |
|---|---|
| `apps/shell.nix` | fish, starship, eza, zoxide, ripgrep, fd, fzf, btop, fastfetch, lsd, bat, pv, tree, jq, yq |
| `apps/editors.nix` | helix, neovim, zed-editor, kate, gnome-text-editor, crush, git |
| `apps/media.nix` | mpv, mpd, rmpc, yt-dlp, ffmpeg, ffmpegthumbnailer, cava, transmission (optional) |
| `apps/office.nix` | libreoffice, zathura, firefox, thunderbird, thunar, tumbler, file-roller, prusa-slicer, orca-slicer |
| `desktop/panacea.nix` | hyprland, quickshell, hyprpaper, hyprsunset, hypridle, foot, grim, slurp, wl-clipboard, cliphist, wf-recorder, swaylock, yazi, voxtype, tesseract, and the rest of the shell's runtime |
| `desktop/theme.nix` | JetBrains Mono Nerd Font, Material Design icons, Noto fonts, Bibata cursors, Kora and Papirus icons |
| `crypto/*` | monero-gui, bitcoin and bitcoind, wireguard-tools |
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
| `signal` | Signal desktop (`gurk`) |
| `ls`, `ll`, `la` | `lsd`, `lsd -l`, `lsd -la` |
| `music` | `rmpc` (MPD client) |
| `more` | `more -e` |
| `dum` | top 10 largest items in the current directory |
| `!!` | expands to the previous command |
| `Ctrl+O` | inserts the previous command |

The prompt shows hostname, working directory, git branch, and a non-zero exit
code, with the Linux glyph in the accent colour driven by the Panacea palette.

## Control center

Panacea's settings live in the pill. `SUPER + I` opens them; every section is
also reachable from the pill's expanded island. `SUPER + Z` opens the control
center (Wi-Fi, Bluetooth, audio, power profile). `SUPER + /` lists every current
binding.

---

## Wallpapers

The NixRiot set (13 WebP images, `00.webp` through `12.webp`) ships in
`vendor/panacea/hypr/wallpaper/`, default `00.webp`. Change the wallpaper from
the pill's appearance settings. The manifest is
`vendor/panacea/hypr/wallpaper/WALLPAPERS.md`.

Adding an image means adding a licence entry to that manifest. Live video
wallpapers are not shipped.

---

## Blockchain

Enable in the host config:

```nix
nixriot = {
  crypto.monero = true;
  crypto.bitcoin = true;
};
```

Monero GUI and Bitcoin Core come from nixpkgs. WireGuard is configured through
`nixriot.wireguard`. Wallet files and keys are yours to create and back up; the
flake never ships them.

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

Off by default. To install the curated set, set `nixriot.games = true;` in your
host config. It pulls supertux, openttd, cataclysm-dda, endless-sky, angband,
and brogue-ce. It is deliberately a small subset of OpenRiot's list; several
OpenRiot games are no longer in nixpkgs.

---

## Updating

The flake is the update path. On an installed system:

```sh
sudo nixos-rebuild switch --flake /etc/nixriot#installed
```

To pick up newer packages, update the lock first, from a checkout with network:

```sh
nix flake update
sudo nixos-rebuild switch --flake .#installed
```

Panacea's own updater is disabled on purpose; it would fight the flake.

---

## Advanced: build your own image

For a reproducible build of your own, or an air-gapped install, build the ISO
from source on any machine running Nix with flakes enabled:

```sh
git clone git@github.com:CyphrRiot/NixRiot.git
cd NixRiot
nix build .#iso
```

The image lands at `result/iso/nixos-*.iso`. It is a hybrid image, so `dd` it to
a USB stick as in Download. Building needs about 40 GB of free space and network
access for the first `nix flake lock`.

---

## Troubleshooting

- **Notes are not installed.** Panacea's `notes` action points at Obsidian, which
  NixRiot does not ship, so `SUPER + O` is rebound to the text editor. Install
  Obsidian or rebind it from the settings panel.
- **The greeter does not look like Panacea.** The SDDM theme may need a Qt5/Qt6
  shim depending on the SDDM version in nixpkgs. The session still works.
- **The install failed partway.** Re-run `sudo nixriot-install`; it wipes and
  starts over.
- **No network during install.** The first cut needs network to build the
  target. Offline installs are not implemented yet.
- **Voice to text does nothing.** `voxtype` needs a speech model downloaded; it
  is not packaged.

---

## Licence and credits

NixRiot's own code is MIT. Panacea is MIT. OpenRiot is MIT. Wallpapers, fonts,
and bundled assets keep their original authors' terms.

- [NixOS](https://nixos.org)
- [Panacea](https://github.com/EnsixD/Panacea)
- [OpenRiot](https://github.com/CyphrRiot/OpenRiot)
