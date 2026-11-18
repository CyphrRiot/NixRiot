#!/bin/bash
#
#   focusapp.sh <hint>
#

hint="$1"
[ -n "$hint" ] || exit 0
base="${hint%.desktop}"

if [ -n "$NIRI_SOCKET" ] || [ "${XDG_CURRENT_DESKTOP,,}" = "niri" ]; then
    win_id=$(niri msg --json windows 2>/dev/null | jq -r --arg h "$base" '
        ($h | ascii_downcase) as $l
        | ($l | split(".") | last) as $short
        | map(select(
              ((.app_id // "") | ascii_downcase | contains($l))
              or ((.app_id // "") | ascii_downcase | contains($short))
              or ((.title // "") | ascii_downcase | contains($short))
          ))
        | .[0].id // empty')
    if [ -n "$win_id" ]; then
        niri msg action focus-window --id "$win_id" >/dev/null 2>&1
        exit 0
    fi
fi

addr=$(hyprctl -j clients 2>/dev/null | jq -r --arg h "$base" '
    ($h | ascii_downcase) as $l
    | ($l | split(".") | last) as $short
    | map(select(
          ((.class // "") | ascii_downcase | contains($l))
          or ((.initialClass // "") | ascii_downcase | contains($l))
          or ((.class // "") | ascii_downcase | contains($short))
          or ((.initialClass // "") | ascii_downcase | contains($short))
          or ((.title // "") | ascii_downcase | contains($short))
      ))
    | .[0].address // empty')

if [ -n "$addr" ]; then
    #
    out=$(hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" 2>&1)
    case "$out" in
        ok*) ;;
        *) hyprctl dispatch focuswindow "address:$addr" >/dev/null 2>&1 ;;
    esac
    exit 0
fi

for d in "$HOME/.local/share/applications" /usr/share/applications \
         /var/lib/flatpak/exports/share/applications \
         "$HOME/.local/share/flatpak/exports/share/applications"; do
    f="$d/$base.desktop"
    if [ -f "$f" ]; then
        gio launch "$f" >/dev/null 2>&1 &
        exit 0
    fi
done

short="${base##*.}"
for c in "$base" "$short"; do
    if command -v "$c" >/dev/null 2>&1; then
        setsid "$c" >/dev/null 2>&1 &
        exit 0
    fi
done
exit 0
