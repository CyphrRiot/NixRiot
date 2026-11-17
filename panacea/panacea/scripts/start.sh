#!/usr/bin/env bash
# Start the Panacea Quickshell session.
set -u
conf="${XDG_CONFIG_HOME:-$HOME/.config}/panacea"
# Keep the shell independent of the terminal or updater that launched it.
if [ "${PANACEA_SERVICE_PROCESS:-0}" != "1" ] && command -v systemctl >/dev/null 2>&1 && [ -f "$conf/panacea-shell.service" ]; then
    units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    mkdir -p "$units"
    if ! cmp -s "$conf/panacea-shell.service" "$units/panacea-shell.service"; then
        cp "$conf/panacea-shell.service" "$units/panacea-shell.service"
        systemctl --user daemon-reload
    fi
    systemctl --user import-environment WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP >/dev/null 2>&1 || true
    if systemctl --user start panacea-shell.service; then exit 0; fi
fi
export QSG_RENDER_LOOP="${QSG_RENDER_LOOP:-threaded}"
# Dunst can be D-Bus activated while Panacea is restarting and then owns the
# notification name. Stop only this competing service when Panacea's own
# notification server is enabled; Dunst remains available when Panacea exits.
settings="$conf/settings.json"
if ! command -v jq >/dev/null 2>&1 || [ ! -f "$settings" ] || ! jq -e '.featNotifications == false' "$settings" >/dev/null 2>&1; then
    systemctl --user stop dunst.service >/dev/null 2>&1 || true
fi
exec qs -p "$conf"
