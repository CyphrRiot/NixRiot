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

STATUS=/var/lib/nixriot/status.json
SERVICE=nixriot-update.service

emit() { printf '%s=%s\n' "$1" "$2"; }

case "${1:-check}" in
    check)
        if ! command -v jq >/dev/null 2>&1 || [ ! -r "$STATUS" ]; then
            emit status unknown
            exit 0
        fi

        # A status older than a day means the check has been failing.
        if [ -n "$(find "$STATUS" -mmin +1440 2>/dev/null)" ]; then
            emit status unknown
            emit error offline
            exit 0
        fi

        installed=$(jq -r '.installed // ""' "$STATUS" 2>/dev/null)
        available=$(jq -r '.available // ""' "$STATUS" 2>/dev/null)
        subject=$(jq -r '.subject // ""' "$STATUS" 2>/dev/null)
        flag=$(jq -r '.updateAvailable // false' "$STATUS" 2>/dev/null)

        if [ -z "$installed" ] || [ -z "$available" ]; then
            emit status unknown
            exit 0
        fi

        emit current "$installed"
        emit latest "$available"
        emit subject "$subject"
        if [ "$flag" = "true" ]; then
            emit status behind
        else
            emit status current
        fi
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
            cut -c1-7 /etc/nixriot-revision > "$whatsnew" 2>/dev/null || echo unknown > "$whatsnew"
            cat "$notes" >> "$whatsnew"
        fi
        exit 0
        ;;

    *)
        echo "usage: update.sh [check|apply]" >&2
        exit 1
        ;;
esac
