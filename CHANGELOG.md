# NixRiot releases

Two-part versions: `1.0`, then `1.1`, then `2.0`. A minor bump is the normal
release; a major bump is a deliberate decision. There is no patch level, so
fixes ship as the next minor.

Newest first. One `## <version>` heading per release, matching `VERSION`. The
updater hands the installed system every section above its own version and
nothing else, so the wording here is exactly what a person reads on the pill's
"What's new" screen.

## Unreleased

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

## How to write these

- Write bullets under `## Unreleased` as you work, not at release time.
- One line per change, in plain language: what a person will notice, not the
  file that changed.
- No commit hashes, no internal names, no refactors nobody can see.
- Add a `### Fixed` heading only when a release mixes fixes with changes.
- `make release` will not run while `## Unreleased` is empty, and it renames that
  heading to the new version for you. Never edit `VERSION` by hand.
