#!/usr/bin/env bash
#
#
#
set -u

CFG="$HOME/.config/panacea/settings.json"
OUT="$HOME/.config/hypr/lua/monitors_data.lua"

[ -f "$CFG" ] || exit 1
command -v jq >/dev/null 2>&1 || exit 1

raw="$(jq -r '.monOverrides // ""' "$CFG")"
[ -n "$raw" ] && [ "$raw" != "null" ] || exit 0

mkdir -p "$(dirname "$OUT")"
tmp="$OUT.new"

{
    echo "-- File is generated: panacea/scripts/genmonitors.sh"
    echo "-- Manual edits are overwritten on the next display settings change."
    echo "return {"
    printf '%s' "$raw" | jq -r '
        to_entries[]
        | "    { output = \"" + .key + "\""
        + ", mode = \"" + (.value.w|tostring) + "x" + (.value.h|tostring)
        + "@" + ((.value.rr|tonumber) | tostring) + "\""
        + ", position = \"" + (.value.pos // "auto") + "\""
        + ", scale = " + (((((.value.scale // 1) * 10000) | round) / 10000) | tostring)
        + ", transform = " + ((.value.transform // 0) | tostring)
        + ", vrr = " + (if .value.vrr then "1" else "0" end)
        + " },"
    ' 2>/dev/null
    echo "}"
} > "$tmp"

if grep -q "^    {" "$tmp"; then
    mv -f "$tmp" "$OUT"
else
    rm -f "$tmp"
fi
