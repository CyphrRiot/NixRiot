# NixRiot internals

Maintainer and agent notes. The user-facing manual is `../README.md`; the
reasoning and roadmap are in `Design.md`. This file is the durable record of how
the system works and why, so it survives a clone.

Last updated: 2026-11-18.

## Decisions, and why

1. **NixOS, not Arch or CachyOS.** Reproducibility and supply-chain
   defensibility are the point. The README intro carries the history.
2. **Panacea is carried in-repo, not a flake input.** First-party copies under
   `panacea/`, no sync tooling. Every deliberate change from upstream goes in
   `panacea/LOCAL-CHANGES.md`.
3. **One flake, with the machine's files inside it.** The installer writes
   `hosts/installed/local.nix` (username, plus any `nixriot` overrides) and
   generates `hosts/installed/hardware-configuration.nix`. Updates preserve
   exactly those two files. A separate per-machine flake was tried and reverted:
   it broke installs and bought nothing.
4. **The live image is an installer, not a desktop.** tty1 autologins as `nixos`
   and runs the installer; the serial console (ttyS0) gives a plain shell. The
   installer runs **only on tty1**; `iso/configuration.nix` guards on `$(tty)`.
   Without that guard every getty runs a copy, and two installers can both reach
   the target disk.
5. **Network is required.** The image is a netinstall: flake inputs plus a
   pre-seed list ship inside it, everything else comes from `cache.nixos.org`.
   There is no offline image. The installer will not touch a disk until
   `cache.nixos.org` answers, and it offers `nmtui` when it does not.
6. **The pre-seed list is about distribution size, not install speed.** The ISO
   must stay under GitHub's 2 GiB per-asset limit. Pre-seeding trades a download
   for an xz-decompress plus a copy, so it does not obviously speed up an
   install, and for our own derivations it trades a build for a copy.
7. **UEFI only.** systemd-boot, Secure Boot off. BIOS is not supported.
8. **No greeter.** `nixriot.autologin` logs the user in; the lock screen is the
   gate. SDDM theme work was dropped for this reason.
9. **Music is Lollypop.** The pill reads MPRIS and nothing else; `mpd` speaks no
   MPRIS, so `mpd`/`rmpc` were removed. Images open in the pill's own viewer
   (`panacea-media.desktop`), video in `mpv` with `mpvScripts.mpris`. Audio MIME
   types are left unset so Lollypop wins from its own desktop entry.
10. **Mullvad ships with its GUI.** The pill's VPN panel (`vpn.py`) only
    *reports*: it lists NetworkManager profiles and detects tunnel interfaces
    (`wg*`, `tun*`, names starting with `mullvad`, ...). It never connects.
11. **Lock and the password vault need PAM `swaylock`.**
    `security.pam.services.swaylock` is set in `modules/desktop/panacea.nix`;
    `lock.qml` and `shell.qml` both use `PamContext { config: "swaylock" }`.
12. **No default password, no default username.** The installer asks for both.
13. **GlyphRiot and fingerprint are opt-in** (`nixriot.crypto.glyphriot`,
    `nixriot.fingerprint.{enable,pam,tod}`).
14. **Zed is not installed.** If it is wanted, it is a one-line option plus a
    writable `~/.config/zed/settings.json` so Panacea's `palette.sh` can theme
    it. Helix and Crush are the defaults.

## Verified package facts

Checked against nixpkgs. Do not re-add removed packages, and use these names.

| Package | Status |
|---|---|
| `lollypop` | present, 1.4.40; MPRIS; the music app |
| `mpvScripts.mpris` | present (mpv-mpris 1.3); makes video appear in the pill |
| `zed-editor` | present, 1.27.0; not installed. There is no `zed` package |
| `mpd`, `rmpc` | present, but removed from the system (no MPRIS) |
| `kora-icon-theme` | present; pulls `breeze-icons.dev` and Qt dev outputs |
| `tumbler` | present; pulls `webkitgtk` via `libgepub` |
| `mullvad` / `mullvad-vpn` | the CLI+daemon, and the Electron GUI |
| `intel-npu-driver`, `level-zero` | present; `nixriot.npu` wires them up |
| `kate` | **not shipped**: use `kdePackages.kate` if ever readded |
| `noto-fonts-cjk` | **split**: `noto-fonts-cjk-sans`, `noto-fonts-cjk-serif` |
| `noto-fonts-emoji` | **renamed**: `noto-fonts-color-emoji` |
| `noto-fonts-extra` | **gone**: use `noto-fonts-lgc-plus` |
| `gnome-disks` | **renamed**: `gnome-disk-utility` |
| `crush` | present, 0.99.0, `fsl11Mit` (unfree; `allowUnfree` is set) |
| `gurk-rs` | present, 0.10.2; the `signal` alias and its launcher entry |
| `quickshell` | present, 0.3.2 |
| `zeroad`, `frozen-bubble` | **removed from nixpkgs** |

## Installer

- `installer/default.nix` builds the `nixriot-install` script. Run it with
  `sudo nixriot-install`.
- Prompt order: username, password, network, disk, `ERASE`, LUKS twice, install,
  reboot. It creates a 512M ESP labeled `BOOT` and the rest as LUKS2 `nixos`,
  `mkfs.ext4` on the mapped volume, and mounts the ESP with
  `fmask=0077,dmask=0077`.
- The passphrase is captured once into a temp keyfile and reused for
  `luksFormat` and `open`, so there are two prompts, not three. The account
  password is collected up front and applied at the end with `chpasswd`.
- It copies `/etc/nixriot` to `/mnt/etc/nixriot`, runs `nixos-generate-config
  --root /mnt --dir /mnt/etc/nixriot/hosts/installed`, writes `local.nix`, and
  runs `nixos-install --root /mnt --flake /mnt/etc/nixriot#installed`.
- Everything is teed to `/tmp/nixriot-install.log` **in the guest**. When an
  install looks stuck, read that file over the serial console before guessing.
- Environment: `NIXRIOT_USER`, `NIXRIOT_DISK`, `NIXRIOT_PASSPHRASE`,
  `NIXRIOT_PASSWORD`, `NIXRIOT_FLAKE`, `NIXRIOT_OFFLINE`, `NIXRIOT_REBOOT`.
  Setting `NIXRIOT_DISK` makes the whole run unattended.

## Update path

- `modules/update.nix` installs `nixriot-update` and two systemd units.
- `nixriot-update-check.timer`: `OnBootSec=5min`, `OnUnitActiveSec=4h`,
  `RandomizedDelaySec=10min`, `Persistent=false`. It compares
  `/etc/nixriot-revision` against GitHub main and writes
  `/var/lib/nixriot/status.json`. It fails soft.
- `nixriot-update.service` is a privileged oneshot, startable by `wheel` through
  a polkit rule. `apply`:
  - clones upstream into a temp dir,
  - `rsync -a --delete` into `/etc/nixriot`, **excluding
    `hosts/installed/local.nix` and `hosts/installed/hardware-configuration.nix`**,
  - writes the new revision to `/etc/nixriot-revision`,
  - `nixos-rebuild switch --flake /etc/nixriot#installed`,
  - writes `/var/lib/nixriot/release-notes.txt` from `git log`.
- `/etc/nixriot-revision` is a real file, written by the installer and the
  updater. It is not derived from the flake: the machine's tree is evaluated as
  a path input, which has no `self.rev`. On the ISO,
  `environment.etc."nixriot-image-revision"` carries the build-time revision and
  the installer copies it into place.
- `panacea/scripts/update.sh` is the adapter between Panacea's update UI and
  `nixriot-update`: `check` answers in key=value from the status file, `apply`
  starts the service and writes `~/.config/panacea/.whatsnew`.

## Releases

- `VERSION` is the single source of truth: two parts, `1.0`, then `1.1`, then
  `2.0`. Minor is the normal release, major is deliberate, and there is no patch
  level, so fixes ship as the next minor.
- `CHANGELOG.md` holds short hand-written notes, newest first, one `## <version>`
  heading per release matching `VERSION`. Work in progress goes under
  `## Unreleased`.
- The installed system reads its own copies, `/etc/nixriot/VERSION` and
  `/etc/nixriot/CHANGELOG.md`, so no stamp file is involved: an update replaces
  both files with the tree.
- `nixriot-update check` fetches both from
  `raw.githubusercontent.com/<repo>/main` and compares the versions. It does not
  use the GitHub API, so there is no rate limit and no commit-hash comparison. A
  commit that does not bump `VERSION` is not offered to anyone.
- `status.json` keeps its shape, so the pill shows `1.0 -> 1.1`: `installed` and
  `available` carry versions, and `subject` is the first bullet of the new
  version's entry.
- The notes a machine shows are the changelog sections *above* its own version,
  sliced by `nixriot-update apply` and written to
  `/var/lib/nixriot/release-notes.txt`. `panacea/scripts/update.sh` turns that
  into `~/.config/panacea/.whatsnew`, with the version as the first line. If the
  changelog is missing or the installed version is unknown, the notes fall back
  to commit subjects from the clone.
- Publishing (bump, guards, editor prompt, tag, ISO build, `SHA256SUMS`,
  `gh release create`) is `make release` and `make publish`. The mechanics and
  the rules are in `AGENTS.md` under Releasing.

## Testing in QEMU

```
qemu-system-x86_64 -enable-kvm -machine q35 -cpu host -smp 4 -m 8G \
  -drive if=pflash,format=raw,readonly=on,file=<OVMF_CODE.fd> \
  -drive if=pflash,format=raw,file=<copy of OVMF_VARS.fd> \
  -vga std -display gtk \
  -chardev socket,id=ser,path=<vm>/serial,server=on,wait=off,logfile=<vm>/serial.log \
  -serial chardev:ser \
  -cdrom result/iso/NixRiot.iso -boot order=d,menu=on \
  -drive file=<vm>/disk.qcow2,if=virtio,format=qcow2 \
  -netdev user,id=n0 -device virtio-net-pci,netdev=n0
```

- `-display gtk` under Wayland repaints only when it gains or loses focus, so
  typing looks dead until you switch windows. `gtk,gl=on` fails outright
  (`GtkGLArea console lacks DMABUF support`). `-display sdl` avoids both.
- Keep VM files under `~/vms`, never `/tmp`: `/tmp` is tmpfs, and a qcow2 there
  consumes RAM until the backing store fails with EIO inside the guest.
- `cache=unsafe` and a fresh qcow2 per run make installs noticeably faster.
- The serial console is a `bash` shell (ttyS0); the installer runs on tty1. Use
  it to read the guest's install log:
  `printf 'cat /tmp/nixriot-install.log\n' | socat -u - UNIX-CONNECT:<serial socket>`
  Pace the input: the guest's tty drops bytes if the command arrives too fast.

## Known risks

- Panacea tracks Hyprland and Quickshell closely. nixpkgs carries Quickshell
  0.3.2. Panacea's QML imports `QtMultimedia`; without it on the QML import path
  (`modules/desktop/panacea.nix`) the shell refuses to load. `QML2_IMPORT_PATH`
  and `QML_IMPORT_PATH` are both set for `qtmultimedia`.
- `QtWebEngine` was deliberately removed. Panacea reaches it only through
  `Loader { source: "IslandWebView.qml" }`, so the shell loads without it and
  only the chat page breaks. Verified by running the shell headlessly.
- **The ISO carries the repo**, so any repo change needs an ISO rebuild before an
  installed system can see it.
- Panacea's scripts assume Arch paths in a few places; audit each feature as it
  is exercised. `palette.sh` rewrites `~/.config/{fastfetch,foot,fish,zed,btop,…}`
  at run time, so those files must stay writable copies, never Home Manager
  store symlinks.
- `hardware.firmware` is `mkForce`d to a trimmed list in `modules/nixriot.nix`;
  anything that adds firmware must be appended there.
- Cosmetic `buildEnv` collisions exist for `gvfs` and `bitcoind` (duplicates).

## Why installs are slow: fish completions

`programs.fish.generateCompletions` defaults to **true** and, for every package
in the profile, creates a `<package>_fish-completions` derivation with
`runCommandLocal` (`nixos/modules/programs/fish.nix`). `runCommandLocal` is
never substituted from a binary cache, so **every install builds hundreds of
tiny derivations locally, one after another**. A slow install looks like it has
hung on whichever one is currently building. It was seen on
`kora-icon-theme_fish-completions`, which is confusing because kora itself is
pre-seeded and already in the store.

We enable it implicitly with `programs.fish.enable = true` in
`modules/apps/shell.nix`.

Fix: `programs.fish.generateCompletions = false;`. The cost is completions
derived from man pages, and we ship no man pages. Decision pending a full
install run.

## Open questions

- `docs/Design.md` still describes the old installer flow, old milestones, and
  the old ISO-size risk.
