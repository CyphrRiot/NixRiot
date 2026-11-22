# NixRiot release archive

Releases 1.0 through 1.27. The current release notes live in
[`CHANGELOG.md`](../CHANGELOG.md), which keeps the recent sections and the
`## Unreleased` list. Newest first.

## 1.27

- The boot splash is back to the original full-screen image with Plymouth's stock passphrase dialog.
- The pill no longer announces an update right after installing one.
- GTK4 and Firefox popups follow the dark theme.

## 1.26

- The Update button clears as soon as the update finishes.
- What's New shows bullets without the changelog headings.

## 1.25

- Updates apply live and restart the desktop; a new kernel loads on the next reboot.
- Intel panels disable Panel Self Refresh too, so the LUKS prompt appears without pressing Enter.
- The expanded pill has a Wi-Fi chip next to VPN; click it to choose a network.

## 1.24

- Installed systems use the NixRiot splash again; the installer stays text.
- Night light stays applied after suspend instead of needing a manual toggle.

## 1.23

- The live image no longer loads the AMD GPU driver, so it cannot hang before the installer.

## 1.22

- The live image boots on AMD laptops whose GPU hangs at startup, and installed AMD systems disable Panel Self Refresh.
- The installer and installed systems boot in text mode by default; the splash is opt-in.

## 1.21

- The VPN indicator finds the tunnel when the preferred app has no status adapter, and the pill's VPN button controls Mullvad.

## 1.20

- Panacea Viewer steps through the folder with the left and right arrows.

## 1.19

- The pill refreshes the version after an update instead of staying on the old one.

## 1.18

- Update messages say NixRiot, not Panacea.

## 1.17

- Closing the lid suspends from the desktop, so a reboot with the lid shut no longer hangs.

## 1.16

- The `rebuild` alias installs the next boot instead of restarting the desktop.

## 1.15

- The boot splash and LUKS prompt use NixRiot's own theme instead of Plymouth's stock dialog.

## 1.14

- The kernel is pinned to the version that works with the laptop's graphics; the newer one freezes at boot.

## 1.13

- Updates install for the next boot instead of restarting the desktop while it is in use.
- The boot menu keeps the five most recent generations instead of every one.
- The LUKS passphrase prompt is visible on the splash again.
- The terminal background is black again, without the softened tint.

## 1.12

- Stay Awake is remembered across logins instead of turning itself off.
- Reset to defaults now turns Stay Awake off as well.

## 1.11

- `SUPER + SHIFT + Return` opens a centred floating terminal.
- The lock screen follows the pill's 12/24-hour setting.
- The CPU and GPU lines in the shell welcome wrap without repeating their labels.

## 1.10

- The pill shows an Update button when a release is available. The System
  page's Check asks GitHub directly and reports an offline network instead of
  showing stale data.
- The updater checks that your user is still configured, builds the new system
  before switching, keeps a copy of the previous tree, and prints the rollback
  command if the switch fails.
- Five more wallpapers; the default is `22.webp`.
- Labels that showed a literal `\u2026` or `\u0026` now render as characters.
- The keyboard layout badge appears only when more than one layout is set.

## 1.9

- Thunar is gone. Panacea Files is the only file manager, and folders open
  there from every application.
- The pill shows Home and Apps tabs, Applets beside the VPN indicator, and
  notifications, settings and power in the header, with the VPN location
  instead of a bare country code.
- CPU/GPU and weather are on by default; the mascot is off.
- A connected phone appears in Files over MTP.
- The installer asks for a hostname, so a new machine is named from the start.
- Crush 0.101, along with the rest of the November package bump.
- Bluetooth mice and other devices that need a pairing confirmation now pair
  and stay connected.
- LibreOffice replaces AbiWord and Gnumeric, with dark mode. It is opt-in:
  turn on `nixriot.office` if you need it.
- Super+F opens the file manager again, on the same keys OpenRiot used:
  Super+B browser, Super+T process viewer, Super+O text editor, Super+C Crush,
  Super+Shift+K music, Super+M mail, Super+N night light, Print screenshot.
- Web search in the launcher defaults to Brave.
- The window border follows the accent colour instead of red.
- Settings opens at the top of the screen instead of sliding to the middle.
- The pill keeps its width when it opens, and its border is visible again.
- Wallpaper previews no longer fail on a newly added image.
- The display scale suggestion is 1.67, which is what the compositor uses.
- Light-themed GTK dialogs, including Firefox's file picker, follow the dark
  theme.

## 1.8

- Fix conflicting NPU settings in hardware
- Support ThinkPad X1 series laptops
- Other minor bug fixes

## 1.7

- The pill's System page names NixRiot, links to it, and shows the NixRiot
  version instead of the shell's.

## 1.6

- Windows are framed with the accent colour, not white.

## 1.5

- Signal Desktop is included, and the launcher's Signal opens it. The terminal
  client it used to open, gurk, is now Signal TUI.

## 1.4

- Upgrading updates the desktop itself, not just the system: changes to
  keybindings, the cursor and the shell's scripts used to reach fresh installs
  only.
- The pointer is white again. The compositor drew a black cursor while
  applications drew a white one, because the two were told different themes.

## 1.3

- The screen locks itself after ten minutes without input.
- Closing the lid suspends, unless a second display is attached: a laptop on an
  external monitor stays awake with the lid shut instead of locking and sleeping.
- Night light, off until you switch it on with `SUPER + N` or from the card in
  Settings → Display. It comes on at 4000K and can follow an evening schedule.
- Updating from the pill works: it could report an update but never install one.

## 1.2

- Installing is much faster: the system no longer builds a fish completion file for every package, one at a time.
- Adds firmware for Realtek RTL8192SU USB Wi-Fi adapters

## 1.1

- Focus follows a click instead of the pointer: moving the mouse across a window
  no longer switches to it.
- The system no longer tries to import a ZFS root pool while booting.

## 1.0

First release.

- Installs from a network image, encrypts the disk with LUKS, and boots to the
  desktop with no login prompt.
- Hyprland with the Panacea pill: launcher, control centre, lock screen, and the
  wallpaper set.
- Music in Lollypop and video in mpv, both visible to the pill.
- Mullvad VPN with its desktop app.
- Tiled windows keep a border and sit flush, the way OpenRiot arranged them.
