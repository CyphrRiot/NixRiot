# NixRiot releases

Two-part versions: `1.0`, then `1.1`, then `2.0`. A minor bump is the normal
release; a major bump is a deliberate decision. There is no patch level, so
fixes ship as the next minor.

Newest first. One `## <version>` heading per release, matching `VERSION`. The
updater hands the installed system every section above its own version and
nothing else, so the wording here is exactly what a person reads on the pill's
"What's new" screen.

## Unreleased

## 1.39

- The passphrase prompt appears without pressing a key.

## 1.38

- Install optional applications from the Installs page in Settings.
- WebP images open in the viewer instead of showing black.

## 1.37

- Fix Plymouth logo and Installer

## 1.36

- Installing an optional app no longer flips the button before the rebuild finishes.

## 1.35

- Optional apps can be installed from Settings → Installs.

## 1.34

- Fix Text Editor blur issue

## 1.33

- Crush ships as the upstream binary instead of compiling on every machine.
- The text editor stays opaque and unblurred, so scrolling leaves no stray pixels.

## 1.32

- Fix Crush and NixRiot hostname issues

## 1.31

- Crush comes from current nixpkgs without moving the system kernel pin.
- The VPN location is bold text instead of a white bubble.
- The Plymouth spinner uses the Panacea logo again instead of a blank image.

## 1.30

- The desktop shell restarts itself if an update or a bus restart kills it.
- GTK4 and Firefox use the system dark preference again instead of an invalid GTK4 theme name.

## 1.29

- The update card shows the installed and new versions.
- Plymouth starts before the initrd cryptsetup target, so the passphrase prompt is on the splash.
- The Wi-Fi chip sits left of the applet row instead of underneath it.

## 1.28

- Intel panels also disable FBC and display C-states, and AMD disables DSC, so the LUKS prompt appears without a keypress.
- The initrd starts Plymouth before the LUKS unlock and enables its passphrase agent, so the prompt is on the splash instead of the hidden text console.
- The fish prompt uses OpenRiot's teal, cyan, and blue colours again.

Releases before 1.28 are in [docs/CHANGELOG-archive.md](docs/CHANGELOG-archive.md).

## How to write these

- Write bullets under `## Unreleased` as you work, not at release time.
- One line per change, in plain language: what a person will notice, not the
  file that changed.
- No commit hashes, no internal names, no refactors nobody can see.
- Add a `### Fixed` heading only when a release mixes fixes with changes.
- `make release` will not run while `## Unreleased` is empty, and it renames that
  heading to the new version for you. Never edit `VERSION` by hand.
