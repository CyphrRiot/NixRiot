#!/bin/bash
#

DIR="$(dirname "$(readlink -f "$0")")"
QML="$DIR/../lock.qml"

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/panacea/lock.log"
mkdir -p "$(dirname "$LOG")" 2>/dev/null
step() { printf '%s %s\n' "$(date +%H:%M:%S)" "$1" >> "$LOG"; }
: > "$LOG" 2>/dev/null
step "starting, PATH=$PATH"

if pgrep -f "quickshell --path .*lock\.qml" >/dev/null; then
    step "already locked, exiting"
    exit 0
fi

wallpaper=$(grep -m1 '^\$wallpaper' "$HOME/.config/hypr/wallpaper.conf" 2>/dev/null \
            | cut -d= -f2- | sed 's/^ *//; s/ *$//')
wallpaper="${wallpaper/#\~/$HOME}"

if [ -n "$wallpaper" ] && [ "$wallpaper" != "black" ] && [ -f "$wallpaper" ]; then
    bg=$("$DIR/thumbs.sh" lockbg "$wallpaper" 2>/dev/null)
    [ -n "$bg" ] && export PANACEA_LOCK_BG="$bg"
fi
step "background ready: ${PANACEA_LOCK_BG:-none}"
command -v quickshell >/dev/null 2>&1 || step "quickshell not found in PATH"

export QSG_RENDER_LOOP="${QSG_RENDER_LOOP:-threaded}"

step "starting $QML"
exec quickshell --path "$QML" 2>>"$LOG"
