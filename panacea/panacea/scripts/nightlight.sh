#!/usr/bin/env bash
# Night light: a warm colour filter over the screen.
#
#   nightlight.sh on [K]   turn on, default 4000K (OpenRiot's temperature)
#   nightlight.sh off      turn off
#   nightlight.sh status   print on or off
#
# The filter is applied by hyprsunset through CTM, so it is part of the
# composited output: screenshots and recordings carry it, unlike a shader.
#
# Upstream Panacea also drives wlsunset for niri. NixRiot does not carry niri,
# so only the hyprsunset path is here.
set -u

STATE="${XDG_RUNTIME_DIR:-/tmp}/panacea-nightlight"
ON_TEMP=4000

# hyprsunset clamps to 1000-20000K and rejects anything else.
clamp() {
    local t="${1:-$ON_TEMP}"
    case "$t" in *[!0-9]*) t=$ON_TEMP ;; esac
    [ "$t" -lt 1000 ] && t=1000
    [ "$t" -gt 20000 ] && t=20000
    printf '%s\n' "$t"
}

usable() {
    command -v hyprctl >/dev/null 2>&1 || return 1
    command -v hyprsunset >/dev/null 2>&1 || return 1
    [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || return 1
}

case "${1:-}" in
    on)
        usable || exit 1
        temp="$(clamp "${2:-}")"
        # Autostart usually has the daemon up already. Start it here too, so the
        # toggle still works if that did not run.
        if ! pgrep -x hyprsunset >/dev/null 2>&1; then
            setsid hyprsunset >/dev/null 2>&1 &
            sleep 0.4
        fi
        hyprctl hyprsunset temperature "$temp" >/dev/null 2>&1 || exit 1
        printf '%s\n' "$temp" > "$STATE"
        ;;
    off)
        usable || exit 1
        # The daemon stays up at identity: restarting it flashes the screen.
        hyprctl hyprsunset identity >/dev/null 2>&1 || exit 1
        rm -f "$STATE"
        ;;
    status)
        if [ -f "$STATE" ] && pgrep -x hyprsunset >/dev/null 2>&1; then
            echo on
        else
            echo off
        fi
        ;;
    *)
        echo "usage: nightlight.sh on [temperature] | off | status" >&2
        exit 1
        ;;
esac
