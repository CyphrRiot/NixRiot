#!/bin/bash
# Live wallpapers: video instead of a still image behind the desktop.
#
#   dir            -> prints the live wallpaper directory (creating it)
#   list           -> lines  name|poster|active(yes|no)|path
#   set <path|name> -> put a video in the background
#   stop           -> go back to the ordinary wallpaper
#   state          -> prints the path of the current video, or nothing
#   warm           -> catch up on posters for every video
#
# mpvpaper plays it: it puts mpv on the background layer, so windows and the
# pill stay on top. hyprpaper is turned off meanwhile, since two background
# layers would fight over the same screen.
#
# State lives in wallpaper.conf alongside the ordinary wallpaper ($live).
# Nothing includes that file via source, so changing the background does not
# touch the Hyprland configs.

LIVE_DIR="$HOME/.config/hypr/wallpaper/live"
STATE="$HOME/.config/hypr/wallpaper.conf"
THUMBS="${XDG_CACHE_HOME:-$HOME/.cache}/panacea/thumbs"
SWITCH="$(dirname "$0")/switch_theme.sh"

mkdir -p "$LIVE_DIR"

live_state() {
    grep -m1 '^\$live' "$STATE" 2>/dev/null | cut -d= -f2- | sed 's/^ *//; s/ *$//'
}
still_state() {
    grep -m1 '^\$wallpaper' "$STATE" 2>/dev/null | cut -d= -f2- | sed 's/^ *//; s/ *$//'
}

# Write $live while keeping the line with the ordinary wallpaper: stop returns
# to it.
save_live() {
    local v="$1" still
    still=$(still_state)
    {
        printf '# This file is written automatically when the wallpaper changes.\n'
        printf '# Hyprland does not include it: changing the picture must not touch the config.\n'
        printf '$wallpaper = %s\n' "$still"
        [ -n "$v" ] && printf '$live = %s\n' "$v"
    } > "$STATE"
}

poster() {
    # A frame from the middle of the video, the preview for the carousel. It
    # goes into the shared thumbnail cache: the carousel reads both images and
    # videos from one place.
    local src="$1" name dst dur pos
    name=$(basename "$src"); name="${name%.*}.jpg"
    dst="$THUMBS/$name"
    if [ ! -f "$dst" ] || [ "$src" -nt "$dst" ]; then
        mkdir -p "$THUMBS"
        dur=$(ffprobe -v error -show_entries format=duration \
                      -of default=nw=1:nk=1 "$src" 2>/dev/null)
        pos=$(awk -v d="$dur" 'BEGIN{ if (d > 2) printf "%.1f", d/2; else print 0 }')
        ffmpeg -loglevel error -y -ss "$pos" -i "$src" -frames:v 1 \
               -vf "scale=1100:-1" -q:v 5 "$dst" </dev/null || return 1
    fi
    printf '%s\n' "$dst"
}

resolve() {
    local n="$1"
    n="${n/#\~/$HOME}"
    [ -f "$n" ] && { printf '%s\n' "$n"; return 0; }
    find "$LIVE_DIR" -maxdepth 1 -type f -iname "$n.*" -print -quit | grep . && return 0
    return 1
}

case "$1" in
dir)
    printf '%s\n' "$LIVE_DIR"
    ;;

state)
    live_state
    ;;

list)
    cur=$(live_state)
    find "$LIVE_DIR" -maxdepth 1 -type f \
         \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) \
         | sort | while read -r v; do
        base=${v##*/}
        name=${base%.*}
        [ "$v" = "$cur" ] && act=yes || act=no
        # The poster is returned only if it already exists: pulling frames out
        # of dozens of videos while building the list means seconds of waiting,
        # and "warm" catches up on those.
        p="$THUMBS/$name.jpg"
        [ -f "$p" ] && [ ! "$v" -nt "$p" ] || p=""
        printf '%s|%s|%s|%s\n' "$name" "$p" "$act" "$v"
    done
    ;;

warm)
    find "$LIVE_DIR" -maxdepth 1 -type f \
         \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) \
         | while read -r v; do poster "$v" >/dev/null; done
    ;;

set)
    [ -z "$2" ] && exit 1
    vid=$(resolve "$2") || { echo "video not found: $2" >&2; exit 1; }

    pkill -x hyprpaper >/dev/null 2>&1
    pkill -x mpvpaper  >/dev/null 2>&1
    sleep 0.2

    # mpv options go WITHOUT double dashes: mpvpaper passes the string to its own
    # parser, and "--loop-inf" never reached mpv, so the video played to the end
    # and the screen went black.
    #   loop-file=inf  the wallpaper must not end
    #   keep-open=yes  even if something goes wrong, the last frame stays rather
    #                  than black
    #   no-audio       the wallpaper makes no sound
    #   hwdec          decoding moves to the GPU where possible
    MPV_OPTS="loop-file=inf keep-open=yes no-audio hwdec=auto-safe vo=gpu"

    # One instance per monitor, not one for everything via "*".
    # mpvpaper's autopause is counted per instance: with one shared across all
    # outputs, a fullscreen window on one monitor also stopped the wallpaper on
    # the others.
    #
    # -p (and only it): mpv sleeps while the wallpaper is covered. The -a MAX
    # flag is deliberately absent here, since it extends the pause to ANY
    # fullscreen window in the system, not to the one covering the wallpaper
    # itself.
    mons=$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name')
    [ -n "$mons" ] || mons='*'
    for M in $mons; do
        mpvpaper -f -p -l background -o "$MPV_OPTS" "$M" "$vid" >/dev/null 2>&1
    done

    save_live "$vid"
    ;;

stop)
    pkill -x mpvpaper >/dev/null 2>&1
    save_live ""
    # bring back the picture that was there before the live wallpaper
    [ -x "$SWITCH" ] && "$SWITCH" --restore >/dev/null 2>&1
    ;;

*)
    echo "usage: live_wallpaper.sh dir|list|set <video>|stop|state|warm" >&2
    exit 1
    ;;
esac
