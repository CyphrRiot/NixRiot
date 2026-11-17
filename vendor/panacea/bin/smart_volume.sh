#!/bin/bash
# Volume in even steps, accelerating while a key is held.
#
# Base step is 5%. Hyprland calls the script again and again while the key is
# held, so we measure the pause between calls: if they come back to back, the
# step grows.
#
# wpctl can do relative steps (5%+), but if the current value is not a multiple
# of five it stays that way: 43 -> 48 -> 53. So we do the arithmetic ourselves:
# round the current level to a multiple of the step and go from there.

SINK="@DEFAULT_AUDIO_SINK@"
MAX=100

STATE="${XDG_RUNTIME_DIR:-/tmp}/panacea-vol.streak"
GAP_MS=280          # a longer pause counts as the hold being released

now_ms() { date +%s%3N; }

# --- work out the length of the current run of presses
streak=0
if [ -f "$STATE" ]; then
    read -r last prev_streak < "$STATE" 2>/dev/null
    if [ -n "$last" ] && [ $(( $(now_ms) - last )) -lt $GAP_MS ]; then
        streak=$(( prev_streak + 1 ))
    fi
fi
echo "$(now_ms) $streak" > "$STATE"

# --- the step grows as the key is held
if   [ "$streak" -lt 4 ];  then STEP=5
elif [ "$streak" -lt 10 ]; then STEP=10
else                            STEP=20
fi

cur_pct() {
    # "Volume: 0.45" or "Volume: 0.45 [MUTED]"
    wpctl get-volume "$SINK" | LC_ALL=C awk '{printf "%d", $2 * 100 + 0.5}'
}

set_pct() {
    local p=$1
    [ "$p" -lt 0 ]    && p=0
    [ "$p" -gt $MAX ] && p=$MAX
    wpctl set-volume "$SINK" "${p}%"
}

case "$1" in
    up)
        cur=$(cur_pct)
        set_pct $(( (cur / STEP) * STEP + STEP ))
        # raising the volume clears mute, otherwise it is unclear why it is quiet
        wpctl set-mute "$SINK" 0
        ;;
    down)
        cur=$(cur_pct)
        set_pct $(( ( (cur + STEP - 1) / STEP ) * STEP - STEP ))
        ;;
    mute)
        wpctl set-mute "$SINK" toggle
        ;;
    *)
        echo "usage: smart_volume.sh up|down|mute" >&2
        exit 1
        ;;
esac

# The pill shows the level itself: it watches Pipewire and draws the bar, and
# it does so in every mode. There is no separate power-saving indicator any
# more.
