#!/bin/bash
# Wallpaper change, and only wallpaper.
#
#   switch_theme.sh --restore     restore the last wallpaper (autostart)
#   switch_theme.sh <name>        wallpaper from ~/.config/hypr/wallpaper (without .jpg)
#   switch_theme.sh <path>        any file
#
# With no arguments it asks nothing: the wallpaper choice lives in the pill
# itself (Super + Shift + T), and keeping a second menu on tofi for the same
# thing would mean keeping tofi as well.
#
# Colours are not involved here: there is a single palette in palette.conf, and
# palette.sh lays it out. So changing the picture no longer recolours terminals
# and touches no file that Hyprland itself reads; previously that made the
# workspaces shuffle on every theme.

WALL_DIR="$HOME/.config/hypr/wallpaper"
# A separate file, not theme.conf: nobody includes it via source, so Hyprland
# stays untouched when the wallpaper changes.
STATE="$HOME/.config/hypr/wallpaper.conf"

# The wallpaper path: either a ready file, or a name without extension. We
# search the whole wallpaper directory, not just its root: downloaded sets live
# in subdirectories (shell, custom), and picking such a picture silently ended
# with nothing before.
resolve() {
    local n="$1"
    n="${n/#\~/$HOME}"
    if [ -f "$n" ]; then printf '%s\n' "$n"; return 0; fi
    find "$WALL_DIR" -maxdepth 2 -type f \
         \( -iname "$n.jpg" -o -iname "$n.jpeg" -o -iname "$n.png" -o -iname "$n.webp" \) \
         -print -quit 2>/dev/null | grep . && return 0
    return 1
}

current() {
    grep -m1 '^\$wallpaper' "$STATE" 2>/dev/null \
        | cut -d= -f2- | sed 's/^ *//; s/ *$//'
}

if [ "$1" = "--restore" ]; then
    # a live wallpaper was last, hand it back to its own script and exit
    LIVE=$(grep -m1 '^\$live' "$STATE" 2>/dev/null | cut -d= -f2- | sed 's/^ *//; s/ *$//')
    LIVE="${LIVE/#\~/$HOME}"
    if [ -n "$LIVE" ] && [ -f "$LIVE" ]; then
        exec "$(dirname "$0")/live_wallpaper.sh" set "$LIVE"
    fi
    WALL=$(current)
    [ -n "$WALL" ] || WALL=$(ls "$WALL_DIR"/*.jpg "$WALL_DIR"/*.png "$WALL_DIR"/*.webp 2>/dev/null | head -1)
elif [ -n "$1" ]; then
    WALL=$(resolve "$1")
else
    echo "usage: switch_theme.sh --restore | <name> | <path>" >&2
    exit 1
fi

WALL="${WALL/#\~/$HOME}"
[ -n "$WALL" ] && [ -f "$WALL" ] || { echo "wallpaper not found: $1" >&2; exit 1; }

# Live and static wallpapers are the same background, so enabling a picture
# disables video. Otherwise mpvpaper would keep running underneath it.
if grep -q '^\$live' "$STATE" 2>/dev/null || pgrep -x mpvpaper >/dev/null 2>&1; then
    pkill -x mpvpaper >/dev/null 2>&1
fi

# remember the choice: the pill, the lock screen and autostart read it from here
mkdir -p "$(dirname "$STATE")"
{
    printf '# This file is written automatically when the wallpaper changes.\n'
    printf '# Hyprland does not include it: changing the picture must not touch the config.\n'
    printf '$wallpaper = %s\n' "$WALL"
} > "$STATE"

# ------------------------------------------------------------- hyprpaper
# hyprpaper changed its config format in 0.8: instead of the preload/wallpaper
# pair there is now a wallpaper { monitor, path, fit_mode } block.
#
# The trap is that it does not complain about the old format, it simply does not
# see it: "Monitor eDP-1 has no target, no wp will be created". The picture was
# still set, but only through IPC, that is only while you are logged in. After a
# reboot hyprpaper came up with an empty config, and the desktop stayed black
# until you picked a wallpaper again.
#
# An empty monitor in the new format means "every screen", which also removes
# the dependency on the monitor list at the time of writing: a screen attached
# later gets the same wallpaper.
hyprpaper_new_format() {
    local v maj min
    v=$(hyprpaper --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    [ -n "$v" ] || return 1
    maj=${v%%.*}
    min=$(printf '%s' "$v" | cut -d. -f2)
    [ "$maj" -gt 0 ] || [ "$min" -ge 8 ]
}

{
    if hyprpaper_new_format; then
        printf 'wallpaper {\n'
        printf '    monitor =\n'
        printf '    path = %s\n' "$WALL"
        printf '    fit_mode = cover\n'
        printf '}\n'
    else
        printf 'preload = %s\n' "$WALL"
        # one line per monitor: ",path" does not work on this version
        hyprctl monitors -j | jq -r '.[].name' | while read -r M; do
            printf 'wallpaper = %s,%s\n' "$M" "$WALL"
        done
    fi
    printf 'splash = false\nipc = on\n'
} > "$HOME/.config/hypr/hyprpaper.conf"

# setsid: the script is called both from the shell and from autostart, and
# hyprpaper must not stay on our output and hold the channel open after we exit
pgrep -x hyprpaper >/dev/null || { setsid hyprpaper >/dev/null 2>&1 & sleep 1; }
hyprctl hyprpaper preload "$WALL" >/dev/null 2>&1
hyprctl monitors -j | jq -r '.[].name' | while read -r M; do
    hyprctl hyprpaper wallpaper "$M,$WALL" >/dev/null 2>&1
done

# --------------------------------------------------------- login screen bg
# The greeter runs as the sddm user and cannot look into ~/: the home directory
# is closed. We put a ready, blurred copy in the shared directory that
# install.sh created. Blurring happens ahead of time: a QML blur on the greeter
# costs frames.
SDDM_DIR=/var/lib/panacea
if [ -d "$SDDM_DIR" ] && [ -w "$SDDM_DIR" ] && command -v ffmpeg >/dev/null; then
    # downscale to 1280 before blurring: faster, and the blur is softer
    ffmpeg -y -loglevel error -i "$WALL" \
        -vf "scale=1280:-1,gblur=sigma=28,eq=saturation=0.9" \
        -frames:v 1 "$SDDM_DIR/sddm-bg.jpg" 2>/dev/null \
        && chmod 644 "$SDDM_DIR/sddm-bg.jpg"
fi
