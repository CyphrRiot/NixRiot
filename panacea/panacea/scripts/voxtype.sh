#!/bin/bash
#
#

PATH="$PATH:/usr/bin:/usr/local/bin:$HOME/.local/bin:/bin:/opt/bin"
export PATH

CFG="$HOME/.config/panacea"
ipc() { qs -c "$CFG" ipc call pill "$@" >/dev/null 2>&1; }

find_vox() {
    local p
    p=$(command -v voxtype 2>/dev/null) && { printf '%s\n' "$p"; return 0; }
    for p in /usr/bin/voxtype /usr/local/bin/voxtype "$HOME/.local/bin/voxtype"; do
        [ -x "$p" ] && { printf '%s\n' "$p"; return 0; }
    done
    return 1
}

case "${1:-}" in
    available)
        find_vox >/dev/null 2>&1 && echo yes || echo no
        ;;
    start)
        VOX=$(find_vox) || { ipc voxUnavailable; exit 1; }
        if ! systemctl --user is-active --quiet voxtype 2>/dev/null; then
            systemctl --user start voxtype 2>/dev/null
            sleep 0.2
        fi
        if "$VOX" record start >/dev/null 2>&1 || [ "$("$VOX" status 2>/dev/null)" = "recording" ]; then
            ipc voxListening
        else
            sleep 0.25
            if "$VOX" record start >/dev/null 2>&1 || [ "$("$VOX" status 2>/dev/null)" = "recording" ]; then
                ipc voxListening
            else
                ipc voxUnavailable
                exit 1
            fi
        fi
        ;;
    stop)
        VOX=$(find_vox) || { ipc voxDone; exit 1; }
        ipc voxTranscribing
        "$VOX" record stop >/dev/null 2>&1
        STATE_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/voxtype/state"
        if [ -f "$STATE_FILE" ]; then
            for _ in $(seq 1 200); do
                s=$(cat "$STATE_FILE" 2>/dev/null)
                [ "$s" = "transcribing" ] || [ "$s" = "recording" ] || break
                sleep 0.05
            done
        fi
        ipc voxDone
        ;;
    toggle)
        VOX=$(find_vox) || { ipc voxUnavailable; exit 1; }
        "$VOX" record toggle >/dev/null 2>&1
        ;;
    *)
        echo "usage: voxtype.sh start|stop|toggle|available" >&2
        exit 1
        ;;
esac
