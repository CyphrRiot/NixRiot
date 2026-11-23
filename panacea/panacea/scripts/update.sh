#!/usr/bin/env bash
# NixRiot: adapter between Panacea's update UI and the NixOS update service.
#
#   update.sh check   -> prints key=value lines describing the update state
#   update.sh apply   -> starts the privileged update service
#
# Panacea calls this script and parses key=value output (updParse in
# shell.qml). NixOS owns the update itself: check reads the status file that
# nixriot-update writes on its timer, and apply starts the nixriot-update
# systemd unit, which pulls the flake, updates the lock and rebuilds.
#
# The upstream updater is not used. It rewrote the config tree and restarted
# the shell, which the flake replaces.
set -u

SERVICE=nixriot-update.service
RAW="${NIXRIOT_RAW:-https://raw.githubusercontent.com/CyphrRiot/NixRiot/main}"
INSTALLED=/etc/nixriot/VERSION

emit() { printf '%s=%s\n' "$1" "$2"; }

case "${1:-check}" in
    check)
        installed=$(tr -d ' \n' < "$INSTALLED" 2>/dev/null)
        if ! command -v curl >/dev/null 2>&1; then
            emit status unknown
            exit 0
        fi

        available=$(curl -fsS --max-time 10 "$RAW/VERSION" 2>/dev/null | tr -d ' \n')
        if [ -z "$available" ]; then
            emit status offline
            emit error offline
            [ -n "$installed" ] && emit current "$installed"
            exit 0
        fi

        if [ -z "$installed" ]; then
            emit status unknown
            emit latest "$available"
            exit 0
        fi

        if [ "$(printf '%s\n%s\n' "$available" "$installed" | sort -V | head -n1)" = "$available" ]; then
            emit current "$installed"
            emit latest "$available"
            emit status current
            exit 0
        fi

        subject=$(curl -fsS --max-time 10 "$RAW/CHANGELOG.md" 2>/dev/null \
            | awk -v h="## $available" '$0 == h { found = 1; next } found && /^- / { sub(/^- /, ""); print; exit }')

        emit current "$installed"
        emit latest "$available"
        [ -n "$subject" ] && emit subject "$subject"
        emit status behind
        exit 0
        ;;

    apply)
        emit step download
        if ! systemctl start "$SERVICE" >/dev/null 2>&1; then
            emit error install
            exit 1
        fi
        sleep 1
        emit step install
        while systemctl is-active --quiet "$SERVICE"; do sleep 1; done
        if systemctl is-failed --quiet "$SERVICE"; then
            emit error install
            exit 1
        fi
        emit step done

        notes=/var/lib/nixriot/release-notes.txt
        whatsnew="$HOME/.config/panacea/.whatsnew"
        mkdir -p "$HOME/.config/panacea"
        if [ -r "$notes" ]; then
            cat /etc/nixriot/VERSION > "$whatsnew" 2>/dev/null || echo unknown > "$whatsnew"
            cat "$notes" >> "$whatsnew"
        fi
        exit 0
        ;;

    *)
        echo "usage: update.sh [check|apply]" >&2
        exit 1
        ;;
esac
