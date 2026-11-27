#!/usr/bin/env bash
#
# Build a NixRiot ISO that carries this machine's configuration: the
# username and hostname, the Installs selection, and the Panacea settings.
# API keys and application data are deliberately left out.
set -uo pipefail

export PATH=/run/current-system/sw/bin:/run/wrappers/bin:${PATH:-/usr/bin:/bin}

step() { printf 'STEP %s\n' "$*"; }
log()  { printf 'LOG %s\n' "$*"; }
die()  { printf 'ERROR %s %s\n' "${1:-failed}" "${2:-}"; exit 1; }

case "${1:-start}" in
    start) ;;
    *) echo "usage: personaliso.sh start [output-dir]" >&2; exit 2 ;;
esac

base="${XDG_CACHE_HOME:-$HOME/.cache}/nixriot-image"
tree="$base/tree"
out="$base/out"
dest="${2:-$HOME/Downloads}"

cleanup() {
    rm -f "$base/settings.json"
    [ "${_ok:-0}" = 1 ] || rm -rf "$tree"
}
_ok=0
trap cleanup EXIT

command -v nix >/dev/null 2>&1 || die no-nix "nix is not available on this machine"

mkdir -p "$base" || die no-cache "cannot write to $base"
exec 9>"$base/lock" || die no-cache "cannot lock $base"
flock -n 9 || die busy "an image build is already running"

free_bytes() { df -B1 --output=avail "$1" 2>/dev/null | tail -1 | tr -d ' '; }

store_free="$(free_bytes /nix)"
[ "${store_free:-0}" -ge $((8 * 1024 * 1024 * 1024)) ] \
    || die no-store-space "/nix needs about 8 GB free, ${store_free:-0} bytes available"

mkdir -p "$dest" || die no-dest "cannot write to $dest"
dest_free="$(free_bytes "$dest")"
[ "${dest_free:-0}" -ge $((3 * 1024 * 1024 * 1024)) ] \
    || die no-dest-space "$dest needs about 3 GB free"

step "Copying the system configuration"
rm -rf "$tree"
mkdir -p "$tree" || die no-tree "cannot create $tree"
rsync -a --no-owner --no-group --exclude .git --exclude result /etc/nixriot/ "$tree/" \
    || die copy-failed "/etc/nixriot could not be copied"
chmod -R u+w "$tree"

src="$HOME/.config/panacea/settings.json"
dst="$tree/panacea/panacea/settings.json"
if [ -r "$src" ] && [ -f "$dst" ]; then
    step "Carrying your Panacea settings"
    if jq 'del(.aiKey, .weatherKey, .vpnPreferredClient, .updNotifiedVer)' "$src" \
            > "$base/settings.json" 2>/dev/null; then
        mv "$base/settings.json" "$dst"
    else
        log "settings.json did not parse; the image keeps the defaults"
    fi
fi

step "Marking the image as personal"
user_name="$(id -un)"
host_name="$(hostname -s 2>/dev/null || hostname)"
version="$(tr -d ' \n' < /etc/nixriot/VERSION 2>/dev/null || echo unknown)"
{
    printf 'user=%s\n' "$user_name"
    printf 'host=%s\n' "$host_name"
    printf 'version=%s\n' "$version"
    printf 'created=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$tree/personal-image"

step "Building the image"
(cd "$base" \
    && nix build --no-link --print-out-paths --print-build-logs "$tree#iso" \
       >"$out" 2> >(while IFS= read -r line; do printf 'LOG %s\n' "${line:0:200}"; done))
rc=$?
[ "$rc" -eq 0 ] || die build-failed "nix build failed; the log above has the reason"

iso_store="$(tail -1 "$out" 2>/dev/null)"
[ -n "$iso_store" ] || die no-output "the build finished without an image path"
if [ -d "$iso_store" ]; then
    iso_store="$(find "$iso_store" -type f -name '*.iso' 2>/dev/null | head -1)"
fi
[ -n "$iso_store" ] && [ -f "$iso_store" ] || die no-iso "no .iso file in the build output"

name="NixRiot-$host_name-$(date +%Y%m%d).iso"
step "Copying the image to $dest"
cp -f "$iso_store" "$dest/$name" || die copy-failed "the image could not be written to $dest"

step "Writing the checksum"
( cd "$dest" && sha256sum "$name" > "$name.sha256" ) \
    || rm -f "$dest/$name.sha256"

rm -rf "$tree"
_ok=1
printf 'DONE %s\n' "$dest/$name"
