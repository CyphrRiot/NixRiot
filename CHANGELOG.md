# NixRiot releases

## Unreleased

## 2.42

> _"The menu got quieter, the editor stopped flickering, and the boot screen went back to being honest about the password."_

- Text Editor handles Markdown, no longer flickers while scrolling, and appears once in the menu.
- The app menu drops Signal TUI, Proton Mail and X. Files gets its own entry, and a Code shortcut appears in its sidebar when `~/Code` exists.
- btop++ is now System Monitor.
- The Files window grows to fit its sidebar and mounted drives, so the last row is no longer cut off.
- The desktop widgets have a pomodoro timer: 25 minutes of focus, 5 of break, and SUPER + comma starts or pauses it.
- The boot splash is off again. The LUKS prompt shows on the console without pressing Escape.
- The display Scale picker only offers values the compositor accepts.
- The update check no longer fails a rebuild when the changelog fetch is cut short.
- GlyphRiot is installed by default; gurk is CLI-only.
- Crush is updated to 0.102.

## 2.41

- Always update packages
- Always update crush binary if new

## 2.40

- Fix Plymouth boot so you do not have to hit ESC for the LUKS password
- Fix Scale in monitors so it's not brittle

## 2.39

> _"Small mercies: the right half fits, the password prompt comes back, and the Done card knows when to leave."_

- Fix Text Editor rendering issues for GTK apps
- Add .md file support
- SUPER + ALT + Right puts the window on the right half without clipping the edges.
- After a password prompt, the pill returns to the page you were on instead of collapsing.
- Updates no longer ask for a password; the signature is the gate.
- Release checksums are signed now, with the same key as the release tag.
- Installs lists your own packages, so anything added from search is removable from the page.
- A finished install says Done for half a minute, not forever.
- The installer ISO drops GPU firmware it does not boot, so the image fits the GitHub limit again.
- Fix size of Files window to expand if external connections (smb, usb, etc)

## 2.35

## 2.34

> _"The menu learned to say less, and the toolbox got exactly one job."_

- GlyphRiot is installed by default and no longer lives in Installs.
- The app menu is leaner: Signal TUI, Proton Mail and X are gone. 🦩
- A Files entry sits in the menu and opens the Files view directly.
- btop++ is now System Monitor.
- Panacea files and editor are not competing for your attention in the launcher.

## 2.32

> _"The toolbox got quieter and the seed phrase got its own namespace."_

- GlyphRiot is installed by default, not tucked away in Installs; it is on PATH as glyphriot.
- The app menu is leaner: Signal TUI, Proton Mail and X are gone. 🦩
- gurk is CLI-only. If you want it, type gurk in a terminal.
- Settings → Installs still handles LibreOffice, games, Transmission, Monero, Bitcoin and Claude Code.

## 2.30

> _"The boot screen came back, the tomato started ticking, and the releases learned to sign their own work."_

- The graphics driver now loads in the initrd, so the LUKS prompt and the boot splash can use the GPU instead of leaving you a black screen and an Escape key.
- The desktop widgets traded the day progress bar for a pomodoro timer: 25 minutes of focus, 5 of break, a white tomato that starts, pauses and resets. SUPER + comma toggles it.
- The Sound card lists the real outputs as icons, headphones, speakers and Bluetooth, and no longer dresses up idle HDMI ports as speakers.
- Release checksums are signed now, with the same key as the release tag, and the README shows the one command that checks it.
- The config sync compares file contents instead of size and timestamp, so a fix that happens to be the same length actually reaches your machine.
- The manual covers the password vault, moving the island to the bottom, and installing packages from the Installs page.

## 2.28

- Security updates

## 2.27

- Update icon on expanded pill goes to "Update" not "System" now

## 2.26

- Fix HDMI "audio" cruft

## 2.25

- Fix Update bug

## 2.24

- Update gets special treatment

## 2.23

- Switch between Speakers and Headphones in the island, like a boss

## 2.22

- Added an audio selection
- Fixed resolution / monitor bugs

## 2.21

- The password vault's encrypted store is now authenticated, so a modified file is refused instead of decrypted.
- Backup Now refuses to run when the drive is not mounted, instead of silently writing into a local folder.
- The control center's Sound card has Speaker and Headphones buttons, so switching output is one click.
- The installer pins the LUKS cipher, key size, hash and argon2id cost, and writes a header backup that must be copied off the live system before reboot.

## 2.20

- Fish options such as `--command` now render in their own shade instead of matching every other argument.
- The website has a new banner, and links to it now show a proper preview.
- The manual covers the password vault, moving the island to the bottom, and package search in Installs.

## 2.19

- Fix pill at bottom
- Fix fish command colors

## 2.18

> _"The prompt found its colours again, and the island learned to live at the bottom of the screen without disappearing."_

- **Fish colours are readable again.** The prompt is back to OpenRiot teal, commands are near-white, parameters are a muted shade, and the selection is cyan instead of the accent red. The red search and bracket backgrounds are gone.
- **The island works at the bottom.** Moving the pill to the bottom no longer leaves the expanded panel at zero height. The detached panel now measures the space above the capsule instead of the space below it, so it opens where it should.

## 2.17

> _"The page went dark on its own, and the screen finally learned to sleep. A window can now move over to share the desk with the widgets."_

- **LibreOffice opens dark on the first launch.** The desktop installs `gnome-themes-extra`, so `Adwaita-dark` actually exists when GTK asks for it, and the bundled LibreOffice profile writes the dark scheme's `AppBackground` and `FontColor` instead of leaving them unset. Existing profiles are left alone; the fix seeds a new one.
- **The screen sleeps.** Hyprland turns the display off after ten minutes and suspends after twenty, locking first on the way down. "Stay awake" still wins: it holds a `systemd-inhibit` for idle, sleep, and the lid, and hypridle honours it.
- **A window can take the right half.** `SUPER + ALT + Right` makes the active window floating, sizes it to half the monitor width and full height, and pins it to the right edge, leaving the left half of the desk visible for the widgets.
- **Rebuilds stop blanking the screen.** The activation refresh no longer overwrites the generated monitor, keybinding, and input files, so a rebuild does not re-apply the display mode and drop the picture for a frame.
- **The what's-new marker survives a rebuild.** The activation refresh no longer wipes `.whatsnew-seen`, so the window appears once per release instead of every time the system activates.

## 2.16

- Settings → Installs can search nixpkgs by name, install a package with two clicks, and remove it again.
- `SUPER + SHIFT + I` opens Installs directly.

## 2.15

- Packages refreshed to the 21 November nixpkgs: crush 0.101, Firefox 160.0.1, LibreOffice 26.8.3, the 6.18.64 kernel, and restic 0.20.

## 2.14

- The file manager and the media viewer fit the panel instead of running past its bottom: the file list scrolls to the end, and a right-click near the bottom opens where it can be seen
- Fixed Backup issue
- New Desktop video

## 2.13

- The screen no longer blanks at the end of an update: a config reload no longer drops the display to 60 Hz and back.
- Your display and keyboard settings survive an update instead of being reset to the defaults.
- The keybinding and keyboard generators only reload the compositor when what they generate actually changed.
- The Settings window grows to fit the page you are on instead of cutting it off.
- Backup moved to `SUPER + SHIFT + R`, in the shape of the other island shortcuts.
- The "what's new" window is looked for on a timer, so it appears even when the file watch does not fire.
- A backup verifies the files it copied, instead of demanding that the whole home folder match a system that is still running.

## 2.12

- Fixed Backup & Restore bugs

## 2.11

- The screen no longer blanks at the end of an update: the compositor and the shell stop re-applying a display mode that is already set.
- The "what's new" window after an update appears again, and it no longer depends on the updater finishing cleanly.
- A backup says how much it will copy and how much it will delete before it starts, and refuses to run when the drive is too full.
- `SUPER + ALT + B` opens Backup, and the island chip opens it too while a backup runs.
- The island only sits on the top or bottom edge; the left and right positions were broken and are gone.

## 2.10

- The island shows a backup while it runs, with the percentage, and clicking it opens the page.
- The Backup page keeps showing progress when you leave it and come back, and its Cancel button works.

## 2.9

- Vault passwords no longer reach the clipboard history.
- Panacea's system settings can ask for a password now, so the battery charge threshold actually changes.
- Panacea's privileged helper no longer installs files as root when asked.
- The island's edge is a setting: Top, Left, Right or Bottom in Settings → Bar and island.
- Settings → Backup and restore mirrors your home folder to a mounted drive you pick, verifies it, and puts it back.

## 2.8

- The default wallpaper is `02.webp`.
- The battery charge threshold works now, and Panacea's system settings run a root-owned helper instead of a script in your home folder.

## 2.7

- Fix HDMI + Laptop Lid issues

## 2.6

- Claude Code can be installed from Settings → Installs, like LibreOffice.

## 2.5

- Reorder windows so the 🦩 doesn't lose them

## 2.4

- Updates are signed, and an update is refused if the signature does not check out.
- You can add your own packages by name in the machine file, and updates keep them.
- The wallpaper picker lists the set in order, and stops showing old thumbnails after the set changes.

## 2.3

- `SUPER + SHIFT + H` puts the island away, and brings it back. 🦩

## 2.2

- `SUPER + .` opens a prompt that runs a shell command.

## 2.1

- Fixed timezone issue
- Removed SUPER+SHIFT+M which is evil
- Something about a Flamingo 🦩

## 2.0

The release where the installer stops freezing where it used to, and where
updating stops closing what you have open.

- Updating no longer restarts the desktop shell, which was closing Signal and Firefox.
- The installer no longer sends console output to a serial port, which froze the screen on some laptops.
- The island is a capsule with a gap by default instead of a notch; turn Notch mode on in Settings → Bar and island for the old shape.
- Six new wallpapers; the default is now `04.webp`.
- `SUPER + SHIFT + M` no longer quits the desktop.

## How to write these

Two-part versions: `1.0`, then `1.1`, then `2.0`. A minor bump is the normal
release; a major bump is a deliberate decision. There is no patch level, so
fixes ship as the next minor.

Newest first. One `## <version>` heading per release, matching `VERSION`. The
updater hands the installed system every section above its own version and
nothing else, so the wording here is exactly what a person reads on the pill's
"What's new" screen. Keep the prose in this section and the bullets in theirs:
the extractor drops headings, and anything above the first heading is ignored.

- Write bullets under `## Unreleased` as you work, not at release time.
- One line per change, in plain language: what a person will notice, not the
  file that changed.
- No commit hashes, no internal names, no refactors nobody can see.
- Add a `### Fixed` heading only when a release mixes fixes with changes.
- `make release` will not run while `## Unreleased` is empty, and it renames that
  heading to the new version for you. Never edit `VERSION` by hand.
- Releases before 2.0 live in [docs/CHANGELOG-archive.md](docs/CHANGELOG-archive.md),
  so a machine that skips a long way reads the milestone notes rather than
  twenty old sections. The updater stops at this heading, so keep release
  sections above it.
