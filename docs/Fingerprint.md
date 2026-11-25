# Fingerprint plan

Goal: a fingerprint reader that works without editing Nix files. Plug it in,
open Settings, enroll a finger, switch fingerprint unlocking on, and use it for
login, sudo and polkit. No rebuild between those steps.

The rationale for the security gate is decision 18 in `Internals.md`. This file
is the implementation plan.

## What GNOME and Omarchy do

GNOME's Users panel talks to `fprintd` over D-Bus: it lists readers, enrolls
with press progress, names fingers and deletes prints. PAM is enabled by the
distribution, not by the panel.

Omarchy detects the reader from sysfs before `fprintd` starts, invites
enrollment once, and puts a `pam_exec` gate immediately before `pam_fprintd` so
a closed lid cannot leave login waiting for a finger that cannot reach the
reader.

NixRiot already has the compile-time side in `modules/nixriot.nix`
(`nixriot.fingerprint.{enable,pam,tod}`) and the design notes in decision 18.
What is missing is a runtime UI and a way to turn authentication on without a
rebuild.

## Architecture

1. **The daemon is always on** for desktops: `services.fprintd.enable = true`.
   An idle `fprintd` costs nothing and starts no reader when none is present.
   Touch OEM Drivers stay a build-time option because they are packages.
2. **PAM is always installed but gated.** `services.fprintd.enablePam` is a
   build-time switch and cannot be changed from the GUI. Instead, add PAM rules
   directly, with a gate before `pam_fprintd`:
   - gate exits 0 when `/var/lib/nixriot/fingerprint-auth` is absent,
   - gate exits 0 when the lid is closed,
   - gate exits 1 otherwise, so `pam_fprintd` runs.
   Use `security.pam.services.<name>.rules` so login, sudo and polkit all get
   the same order.
3. **The switch is a root-owned marker.** `/var/lib/nixriot/fingerprint-auth`,
   mode 0644. `panacea-root fingerprint on|off` creates or removes it behind
   the existing polkit action. Settings only calls that helper.
4. **Enrollment is user-level.** `fprintd-enroll` over D-Bus, no root, the same
   path GNOME uses. The page reads `fprintd-list` to show enrolled fingers.

Password fallback is never removed. `pam_fprintd` is `sufficient`, so a failed
or missing finger falls through to the password.

## Files

- `modules/nixriot.nix`: set `services.fprintd.enable` for the desktop profile;
  add the gate script and PAM rules; keep `pam` and `tod` options for
  compatibility, with `pam` deprecated in favour of the runtime marker.
- `modules/desktop/panacea-root.nix`: install the gate script at a root-owned
  store path and add the `fingerprint` subcommand.
- `panacea/panacea/scripts/fingerprint-gate.sh`: reads the lid state from
  `/proc/acpi/button/lid/*/state`, and exits according to the marker and lid.
- `panacea/panacea/root/panacea-root`: `fingerprint on|off`, touch or remove the
  marker, no arguments from the caller beyond the verb.
- `panacea/panacea/SetFingerprint.qml`: the page.
- `panacea/panacea/SettingsView.qml`: add it to the Devices group.
- `home/panacea.nix`: ship the gate script if it is not part of the helper
  package.

## UI

Placement: Settings, Devices, Fingerprint. It is hardware, not a policy page.

States:

1. **No reader**: "No fingerprint reader detected." No controls.
2. **Reader, nothing enrolled**: **Add fingerprint**. Shows a finger prompt,
   progress while the reader is touched, and a Cancel button.
3. **Enrolled**: a list of finger names (`Right index finger`, ...) with delete
   buttons, plus **Add another**.
4. **Switch**: **Use fingerprint for login and sudo**, disabled until one print
   exists. Off by default.

Details:

- The switch is only meaningful after enrollment; the UI enforces that order.
- Deleting the last print turns the switch off and removes the marker.
- A reader that needs a TOD driver shows a plain explanation and points at
  `nixriot.fingerprint.tod`; it cannot be installed from Settings.
- Never offer "fingerprint only". The password remains the fallback.

## Phases

1. **Gate and marker.** Daemon always on, gate script, PAM rules, helper
   subcommand. Test with `fprintd-verify`, `sudo -k`, and a closed lid.
2. **Enrollment page.** Detection, add, list, delete. No switch yet.
3. **The switch.** Marker, end-to-end login, sudo and polkit.
4. **Invitation.** One notification on first login when a reader is present and
   nothing is enrolled, remembered in the Panacea state.

## Testing

- `fprintd-enroll` and `fprintd-verify` with a real reader.
- Lid open and closed, with the marker on: closed must skip straight to the
  password.
- `sudo -k; sudo true` and a polkit action (`timedatectl` from the pill).
- Reader removed: login and sudo still work by password.
- Settings shown with no reader, with a reader, with prints, after deleting the
  last print.
- `make test-vault` and `make test-backup` unaffected.

## Risks

- The PAM gate is the one place a mistake can lock a user out of sudo. Test in a
  TTY session before shipping, with a root shell open.
- `pam_exec` path must be root-owned and not user-writable. It lives in the
  store through the module.
- Readers with no `libfprint` support cannot be fixed in software; the UI has to
  say so plainly.
- Suspend and lid handling differs per laptop; the lid check reads the kernel
  state, not logind's opinion.

## Open decisions

1. Whether `nixriot.fingerprint.enable` stays as the daemon switch for
   non-desktop hosts, or disappears in favour of always-on.
2. Finger names: free text or a fixed list. GNOME offers a fixed list; that is
   less work and enough.
3. Whether enrollment should require the account password first (defence against
   an unattended session), or trust the PAM-gated device as GNOME does.
