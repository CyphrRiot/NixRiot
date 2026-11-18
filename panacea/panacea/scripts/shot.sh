#!/bin/bash
#
#
#
#
#

set -u

CFG="$HOME/.config/panacea"
DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
SHOT=""
FROZEN=0

ipc() { qs -c "$CFG" ipc call pill "$@" >/dev/null 2>&1; }

cleanup() {
    [ "$FROZEN" = 1 ] && ipc unfreeze
    [ -n "$SHOT" ] && rm -f -- "$SHOT"
}
trap cleanup EXIT INT TERM HUP

SHOT=$(mktemp -p "${XDG_RUNTIME_DIR:-/tmp}" panacea-shot.XXXXXXXX.ppm) || exit 1

SNAP=0
if grim -t ppm "$SHOT" 2>/dev/null; then SNAP=1; fi

if [ "$SNAP" = 1 ] && ipc freeze "$SHOT"; then
    FROZEN=1
    sleep 0.08
fi

GEOM=$(slurp -b 00000060 -c ffffffff -w 1) || exit 0
[ -n "$GEOM" ] || exit 0

if [ "$FROZEN" = 1 ]; then ipc unfreeze; FROZEN=0; fi

mkdir -p "$DIR" || exit 1
OUT="$DIR/$(date +'Screenshot_%Y-%m-%d_%H-%M-%S').png"

if [ "$SNAP" = 1 ]; then
    python3 "$CFG/scripts/shotcrop.py" "$SHOT" "$GEOM" "$OUT" || exit 1
else
    grim -g "$GEOM" "$OUT" || exit 1
fi

wl-copy -t image/png < "$OUT"
ipc shotCopied "$OUT"
