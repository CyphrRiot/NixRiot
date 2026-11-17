#!/bin/bash
#
# Power saving mode: turns off animations, shadows, blur and rounding.
# Running it again puts everything back.
#
# It used to also swap out the shell: kill the pill and put waybar with wob in
# its place. That was dropped. What saves power here is not memory but work
# that is never redrawn, and that is what these lines switch off. A second set
# of panels had to be kept in parity with the first, and it did not survive
# that: the Wi-Fi menu was written against nmcli although the system uses iwd,
# and half the bar's buttons called programs that were never in the
# dependencies.
#
# This file remembers whether the mode is on. It used to be tracked by a
# commented-out section in hypr/modules/look_and_feel.conf, but the Hyprland
# config has lived in lua/ for a long time and nobody reads the .conf, so the
# script was commenting out lines that changed nothing and keeping a flag in
# them. The runtime directory is the wrong place for it too: the mode has to
# survive a reboot.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/panacea"
STATE="$STATE_DIR/battery-mode"
LOG="${XDG_RUNTIME_DIR:-/tmp}/battery_mode.log"
SHELL="qs -c $HOME/.config/panacea"

# The current monitor: the mode moves it to 120 Hz with VRR. We do not lower
# the refresh rate, because with VRR the driver drops to 48 Hz on its own on a
# static image, and a fixed 60 would give less benefit than a variable 120.
MONITOR_INFO=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true)')
MONITOR=$(echo "$MONITOR_INFO" | jq -r '.name')
WIDTH=$(echo "$MONITOR_INFO" | jq -r '.width')
HEIGHT=$(echo "$MONITOR_INFO" | jq -r '.height')
RES="${WIDTH}x${HEIGHT}"
POS="$(echo "$MONITOR_INFO" | jq -r '.x')x$(echo "$MONITOR_INFO" | jq -r '.y')"
SCALE=$(echo "$MONITOR_INFO" | jq -r '.scale')

enable_battery() {
    echo "Enabling Battery Savings (120Hz VRR + No Effects)..."
    mkdir -p "$STATE_DIR" && : > "$STATE"
    hyprctl keyword monitor "$MONITOR,$RES@120,$POS,$SCALE,vrr,1"
    "$HOME/.config/hypr/scripts/switch_theme.sh" black
    sleep 0.5

    hyprctl eval 'hl.config({ animations = { enabled = false }, decoration = { rounding = 0, shadow = { enabled = false }, blur = { enabled = false } } })'

    # The shell has no reason to move either: the island stops unfolding
    # smoothly and simply changes size.
    $SHELL ipc call pill motion off 2>/dev/null || true
}

disable_battery() {
    echo "Restoring Performance Mode (120Hz VRR + Animations)..."
    rm -f "$STATE"
    hyprctl keyword monitor "$MONITOR,$RES@120,$POS,$SCALE,vrr,1"

    "$HOME/.config/hypr/scripts/switch_theme.sh" minimal
    sleep 0.5

    hyprctl eval '
    local theme = require("theme")
    hl.config({
        animations = { enabled = true },
        decoration = {
            rounding = theme.rounding,
            shadow = { enabled = theme.shadow_enabled },
            blur = { enabled = theme.blur_enabled }
        }
    })
    '

    $SHELL ipc call pill motion on 2>/dev/null || true
}

{
    echo "Running toggle check..."
    if [ -e "$STATE" ]; then
        echo "Disabling battery"
        disable_battery
    else
        echo "Enabling battery"
        enable_battery
    fi
} >> "$LOG" 2>&1
