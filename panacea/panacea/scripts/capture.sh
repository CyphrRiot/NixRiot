#!/bin/bash
#
#

case "$1" in
    on)
        hyprctl dispatch 'hl.dsp.submap("capture")' >/dev/null
        ;;
    off)
        hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null
        qs -c "$HOME/.config/panacea" ipc call pill cancelCapture 2>/dev/null
        ;;
    *)
        echo "usage: capture.sh on|off" >&2
        exit 1
        ;;
esac
