# NixRiot releases

Two-part versions: `1.0`, then `1.1`, then `2.0`. A minor bump is the normal
release; a major bump is a deliberate decision. There is no patch level, so
fixes ship as the next minor.

Newest first. One `## <version>` heading per release, matching `VERSION`. The
updater hands the installed system every section above its own version and
nothing else, so the wording here is exactly what a person reads on the pill's
"What's new" screen.

## Unreleased

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
