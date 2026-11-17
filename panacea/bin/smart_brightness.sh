#!/usr/bin/env bash
# Brightness keys. The real work lives in
# ~/.config/panacea/scripts/brightness.sh: it picks the method (internal panel
# or a monitor over DDC/CI), the accelerated step while a key is held, and the
# pill notification.
#
# This file stays because keybindings.lua points at it and it lives in
# ~/.local/bin, which is on PATH. Brightness settings belong to the shell, not
# the system, and duplicating the logic in two places would mean fixing it
# twice.
exec "${XDG_CONFIG_HOME:-$HOME/.config}/panacea/scripts/brightness.sh" "$@"
