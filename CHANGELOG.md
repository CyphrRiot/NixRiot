# NixRiot releases

## Unreleased

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
