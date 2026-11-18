#!/bin/bash
#

f="$1"
case "$f" in
    file://*)
        f="${f#file://}"
        f=$(printf '%b' "${f//%/\\x}")
        ;;
esac

[ -n "$f" ] || exit 1
exec qs -p "$HOME/.config/panacea" ipc call pill media "$f"
