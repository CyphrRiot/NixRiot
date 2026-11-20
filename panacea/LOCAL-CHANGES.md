# Panacea local changes

Upstream: https://github.com/EnsixD/Panacea at commit
`2d68047e97fecd34802ed8221a0d113f43a0537f` (version 1.0.24).

The trees below are NixRiot's own copies, edited in place. There is no sync
tooling; `UPSTREAM` and `LICENSE` stay for attribution. Nothing is merged:
upstream features are read and ported by hand, and the pin moves only once the
revision has been reviewed, so `UPSTREAM` is the reviewed baseline.

## What is carried

`panacea/`, `hypr/`, `foot/`, `fastfetch/`, `nano/`,
`applications/`, `bin/`, `sddm/`, `LICENSE`, `VERSION`.

## What is not carried

- `install.sh`: the Arch installer. NixRiot replaces it with Nix modules.
- `docs/`, `README.md`, `AGENTS.md`, `.gitignore`, `graphify-out/`,
  `Panacea Vault/`: upstream housekeeping.
- `niri/`: experimental second compositor, not used here.
- `grub/`: NixRiot boots with systemd-boot, so the GRUB theme is not shipped.
- `assets/`: only the `logo*.png` files are kept, under
  `panacea/assets/` because the shell reads `~/.config/panacea/assets/`.
- `wallpapers/`: upstream set is third-party work with mixed terms and is
  not redistributed.

## Changes made

1. `hypr/wallpaper/` is replaced with the NixRiot wallpaper set, `00.webp`
   through `25.webp`, generated for the project.
2. `hypr/wallpaper.conf` and `hypr/hyprpaper.conf` point at
   `~/.config/hypr/wallpaper/16.webp`.
3. Upstream `assets/logo*.png` moved to `panacea/assets/` so the shell
   finds them after the config tree is copied.
4. `hypr/scripts/switch_theme.sh` fallback now includes `*.webp`.
5. `hypr/scripts/palette.sh` is committed executable, so the activation-time
   `-x` check regenerates the palette.
6. `panacea/scripts/start.sh` drops the Arch-only QtWebEngine workaround
   (`/usr/lib/qt6/qml/QtWebEngine/...`), which cannot resolve on NixOS.
7. `panacea/scripts/update.sh` is an adapter between Panacea's update UI and
   NixOS: `check` reads the status file that `nixriot-update` writes on its
   timer and answers in Panacea's key=value format, and `apply` starts the
   privileged `nixriot-update` service. The upstream updater is not used.
8. `grub/` is not carried: NixRiot boots with systemd-boot, so the upstream
   GRUB theme is unused.
9. `hypr/custom/keybinds.conf` and `hypr/custom/keybindings.lua` carry an
   OpenRiot-compatible keybinding overlay: the launcher, browser, file manager,
   process viewer, editor, Crush, music player, clipboard, power menu, and
   screenshot move back to OpenRiot's keys.
10. `hypr/lua/binds_data.lua`, `hypr/lua/monitors_data.lua` and
    `hypr/lua/input_data.lua` ship as empty defaults. Upstream lets them be
    absent and relies on `pcall`; shipping them keeps Hyprland's Lua loader
    from logging a missing-module error before the settings panel generates
    them. `genbinds.sh`, `genmonitors.sh` and `geninput.sh` overwrite them.
11. `hypr/lua/keybindings.lua` used `pcall(require("lua.binds_data"))`, which
    runs `require` before `pcall` and so is not guarded at all: a missing
    `binds_data.lua` aborts the whole config with a dump of every search path.
    Changed to `pcall(require, "lua.binds_data")`, matching `monitors.lua`,
    `input.lua` and `windowrules.lua`.
12. `hypr/theme.lua` uses `gaps_in = 0`, `gaps_out = 0`, `rounding = 8`,
    matching OpenRiot: flush tiled windows, rounded corners, and a 1px border
    on every window. Upstream used 5/5 and rounding 12.
13. `hypr/lua/windowrules.lua` drops the `no-gaps-wtv1` rule, which zeroed
    `border_size` and `rounding` on any workspace with exactly one tiled
    window. That made a lone window borderless, which is the opposite of
    OpenRiot's `default_border pixel 1` with `smart_gaps off`. The `no-gaps-f1`
    rule stays: true fullscreen should have neither border nor rounding.
14. `hypr/scripts/palette.sh` now derives foot's full 16-colour ANSI palette
    from `palette.conf` and writes it to `~/.config/foot/theme`. It previously
    wrote only foreground, background and selection, so foot fell back to its
    own stock palette, which is where the terminal's green came from.
15. `panacea/Mascot.qml` draws smaller eyes: the pupils go from 7x21 to 5x15,
    the containers from 15x29 to 11x21, and the spacing from 7 to 5. The two
    eyes filled most of the 46x38 face before.
16. `hypr/custom/keybindings.lua` and `hypr/custom/keybinds.conf` carry two more
    OpenRiot shortcuts: `SUPER+M` (and `XF86Mail`) opens Proton Mail, and
    `SUPER+X` opens X with `SUPER+Shift+X` for the compose page. OpenRiot put
    Proton Mail on `SUPER+E`, which Panacea already uses for its Files view.
17. `hypr/lua/input.lua` sets `follow_mouse = 0`, so focus changes on click
    instead of on hover. Upstream uses 1, focus follows the mouse, which moves
    focus whenever the pointer crosses a window. The fallback
    `hypr/hyprland.conf` keeps upstream's value on purpose: it is a stopgap for
    a Hyprland without Lua support and is not kept in parity.
18. `hypr/hypridle.conf` is new, and `hypr/custom/autostart.lua` starts
    `hypridle`. Upstream ships a manual lock only; OpenRiot locked the screen
    after 10 minutes idle (`xautolock -time 10`), so that is what this
    restores. Display-off is deliberately not configured: Hyprland 0.56
    replaced the `dpms` dispatcher with the Lua `hl.dpms`, and there is no
    version-independent shell command for it yet. If the reader needs it,
    `hyprctl` accepts a Lua dispatcher expression.
19. The lid binds are removed: `hypr/lua/keybindings.lua` loses `lidOn` and
    `lidOff`, and `hypr/hyprland.conf` loses its `switch:on:Lid Switch` line.
    Both locked the screen on every lid close, which is wrong in clamshell
    mode: a closed lid with a display still attached is a machine in use.
    Suspending on lid close and *not* suspending when a display is attached are
    both logind's own behaviour (`HandleLidSwitchDocked` defaults to `ignore`,
    and more than one connected display counts as docked), and the lock now
    happens on the way into suspend, from hypridle's `before_sleep_cmd`.
20. Night light, ported from upstream `2d68047` rather than merged. New
    `panacea/scripts/nightlight.sh` drives hyprsunset (`on [K]`, `off`,
    `status`, 4000K default, `identity` to turn off); `panacea/shell.qml` gains
    the `nightLight`/`nightTemp`/`nightAuto`/`nightStart`/`nightEnd` settings,
    the apply-and-schedule functions, a moon branch in the OSD icon and an IPC
    `nightlight` target; `panacea/SetDisplay.qml` gains the Display card and
    `panacea/ControlsView.qml` a moon button beside brightness. It is off by
    default, which changes the screen: hyprsunset used to be started at a fixed
    5000K, so it was always warm. `hypr/hyprsunset.conf` now sits at 6000K (the
    daemon's own default) and autostart starts it bare, leaving the saved state
    in charge. `hypr/custom/keybindings.lua` binds `SUPER+N`, as OpenRiot did.
    Upstream's `wlsunset`/niri branch and its `nightAvailable` probe are not
    carried.
21. `panacea/scripts/brightness.sh` gets the PATH prelude already used by
    `voxtype.sh`, and its `pgrep -x qs` guard around the OSD IPC is dropped.
    The guard could only ever suppress the brightness OSD, and the error it
    avoided is already thrown away.

22. Three island fixes ported from the same upstream revision. `shell.qml`
    guards `collapseTimer` on `root.morphing`, so the panel no longer collapses
    on a spurious hover leave while the mask is still morphing; the collapsed
    length is computed from `cfg.mascotEnabled` rather than `mascot.active`,
    which is false exactly when the panel is expanded and so under-reserved the
    width in `pillSide` and `pillKeepVisible`; and `hoverPad`, an invisible trace
    of the collapsed pill kept in the window mask, stops the "bar <-> control
    centre" flicker when a wide pill expands out from under a stationary cursor.
23. `hypr/lua/env.lua` sets the cursor to `Bibata-Modern-Ice`, and so does
    `HYPRCURSOR_THEME`. Upstream sets `Bibata-Modern-Classic`, which is the dark
    variant, while NixRiot told GTK and the session to use Ice in
    `home/gtk.nix` and `modules/desktop/theme.nix`. The two disagreed, so the
    compositor drew a black cursor over a desktop whose applications drew a
    white one. OpenRiot uses Ice throughout, which is what this restores.

## Not yet changed

- Upstream `2d68047` also moves the wallpaper crossfade out of the island into
  its own `WlrLayer.Bottom` window, so the old wallpaper fades under windows
  instead of covering them for a second. Cosmetic, and the largest piece of that
  revision; reviewed and deliberately skipped. The in-island `Image` is still
  there, and the pin is already at that revision, so this is the one hunk left.
- `panacea/scripts/*.sh` still assume common Arch tool names in a few
  places. Audit and patch as each feature is exercised.
- `hypr/scripts/*.sh` still write to `~/.config` directly. That is fine: Home
  Manager now refreshes the tree on every rebuild and those files are
  regenerated afterwards, in the same activation.
