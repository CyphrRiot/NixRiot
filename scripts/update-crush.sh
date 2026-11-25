#!/usr/bin/env bash
# Bump the pinned Crush prebuilt to the latest GitHub release.
#
# NixRiot pins Crush to a tarball plus its hash, so `nix flake update` never
# moves it. Run this before a release, then build: the version, URL, sourceRoot
# and hash in modules/pkgs/crush.nix are rewritten in place.
set -euo pipefail

repo="charmbracelet/crush"
file="$(cd "$(dirname "$0")/.." && pwd)/modules/pkgs/crush.nix"

tag="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name)"
ver="${tag#v}"
[ -n "$ver" ] || { echo "could not read the latest release tag" >&2; exit 1; }

url="https://github.com/$repo/releases/download/$tag/crush_${ver}_Linux_x86_64.tar.gz"
hash="$(nix store prefetch-file --json --hash-type sha256 "$url" | jq -r .hash)"
[ -n "$hash" ] || { echo "could not fetch $url" >&2; exit 1; }

sed -i \
    -e "s/version = \".*\";/version = \"$ver\";/" \
    -e "s|download/v[^/]*/crush_[^/]*_Linux_x86_64.tar.gz|download/$tag/crush_${ver}_Linux_x86_64.tar.gz|" \
    -e "s|hash = \".*\";|hash = \"$hash\";|" \
    -e "s|sourceRoot = \"crush_[^\"]*\";|sourceRoot = \"crush_${ver}_Linux_x86_64\";|" \
    "$file"

echo "crush $ver"
echo "  $hash"
