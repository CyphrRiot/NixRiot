# NixRiot releases

## Unreleased

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
