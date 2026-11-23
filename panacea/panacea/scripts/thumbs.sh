#!/bin/bash
#
#

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/panacea/thumbs"
WALLS="$HOME/.config/hypr/wallpaper"
WIDTH=1100

mkdir -p "$CACHE"

make_thumb() {
    local src="$1"
    [ -f "$src" ] || return 1

    local name stamp
    name=$(basename "$src")
    name="${name%.*}"
    stamp=$(stat -c %Y "$src" 2>/dev/null) || return 1
    local dst="$CACHE/$name-$stamp.jpg"

    if [ ! -f "$dst" ]; then
        ffmpeg -loglevel error -y -i "$src" \
               -vf "scale=$WIDTH:-1" -q:v 5 "$dst" </dev/null || return 1
    fi
    printf '%s\n' "$dst"
}

LOCKBG="${XDG_CACHE_HOME:-$HOME/.cache}/panacea/lockbg"
LOCK_WIDTH=1920

make_lockbg() {
    local src="$1"
    [ -f "$src" ] || return 1
    mkdir -p "$LOCKBG"

    local name stamp
    name=$(basename "$src")
    name="${name%.*}"
    stamp=$(stat -c %Y "$src" 2>/dev/null) || return 1
    local dst="$LOCKBG/$name-$stamp.jpg"

    if [ ! -f "$dst" ]; then
        ffmpeg -loglevel error -y -i "$src" \
               -vf "scale='min($LOCK_WIDTH,iw)':-2" -q:v 2 "$dst" </dev/null || return 1
    fi
    printf '%s\n' "$dst"
}

case "$1" in
    thumb)
        make_thumb "$2"
        ;;
    lockbg)
        make_lockbg "$2"
        ;;
    path)
        src="$2"
        [ -f "$src" ] || exit 1
        name=$(basename "$src"); name="${name%.*}"
        stamp=$(stat -c %Y "$src" 2>/dev/null) || exit 1
        dst="$CACHE/$name-$stamp.jpg"
        [ -f "$dst" ] && printf '%s\n' "$dst"
        ;;
    all)
        keep=$(mktemp)
        find "$WALLS" -maxdepth 2 -type f \
             \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        | while read -r f; do
            make_thumb "$f" >> "$keep"
        done
        # Drop thumbnails whose source is gone or has been replaced: the file
        # name carries the source's mtime, so a stale entry is one that the
        # pass above did not just produce.
        find "$CACHE" -maxdepth 1 -type f -name '*.jpg' | while read -r t; do
            grep -qxF "$t" "$keep" || rm -f "$t"
        done
        rm -f "$keep"
        ;;
    *)
        echo "usage: thumbs.sh thumb <path> | lockbg <path> | all" >&2
        exit 1
        ;;
esac
