#!/usr/bin/env bash
#
# Mirror $HOME to a mounted backup drive, verify the mirror, and write what a
# rebuild needs. The workflow is the one from the OpenBSD sync-system script;
# there is no disk dump here, because on NixOS the configuration plus the data
# is the whole restore.
#
#   backup.sh status  [DEST]
#   backup.sh mount   [DEST]
#   backup.sh backup  [DEST]
#   backup.sh verify  [DEST]
#   backup.sh restore [--go] [DEST]
#
# DEST defaults to /run/media/$USER/Backup.
#
# Output protocol, parsed by panacea/SetBackup.qml:
#   KEY=value                 status fields
#   STEP text                 what is happening now
#   FILE name                 file being transferred
#   PROGRESS pct done total   percentage, bytes done, bytes total
#   DONE ok|drift|cancelled
#   ERROR code detail
set -u

DRIVE="${2:-}"
[ -n "$DRIVE" ] || DRIVE="/run/media/${USER:-$(id -un)}/Backup"
SRC="$HOME"
DEST="$DRIVE/home"
SYS="$DRIVE/system"
LABEL="${NIXRIOT_BACKUP_LABEL:-$(basename "$DRIVE")}"
STAMP="$DRIVE/last-run"
LOG="$DRIVE/backup.log"

case "${1:-}" in
    restore)
        if [ "${2:-}" = "--go" ]; then
            MODE=go
            DRIVE="${3:-}"
            [ -n "$DRIVE" ] || DRIVE="/run/media/${USER:-$(id -un)}/Backup"
            DEST="$DRIVE/home"
        else
            MODE=dry
        fi
        ;;
    *) MODE="" ;;
esac

step() { printf 'STEP %s\n' "$*"; }
done_ok() { printf 'DONE %s\n' "${1:-ok}"; }
die() { printf 'ERROR %s %s\n' "$1" "${2:-}"; exit 1; }

mounted() { findmnt -no SOURCE --target "$DRIVE" >/dev/null 2>&1; }

drive_device() { findmnt -no SOURCE --target "$DRIVE" 2>/dev/null; }

crypto_ok() {
    local dev
    dev="$(drive_device)" || return 1
    [ -n "$dev" ] || return 1
    case "$dev" in /dev/mapper/*) return 0 ;; esac
    lsblk -sno TYPE "$dev" 2>/dev/null | grep -qE '^(crypt|crypto)$'
}

mount_drive() {
    mounted && return 0
    step "Mounting $LABEL"
    udisksctl mount -b "/dev/disk/by-label/$LABEL" >/dev/null 2>&1
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        mounted && return 0
        sleep 0.5
    done
    return 1
}

free_bytes() { df -B1 --output=avail "$DRIVE" 2>/dev/null | tail -1 | tr -d ' '; }

parse_progress() {
    awk -v out="${1:-/dev/null}" '
        /^[[:space:]]*[0-9,]+[[:space:]]+[0-9]+%/ {
            b = $1; p = $2
            gsub(",", "", b); gsub("%", "", p)
            t = (p + 0) > 0 ? int(b * 100 / p) : 0
            printf "PROGRESS %s %s %s\n", p, b, t
            print p, b, t > out
            close(out)
            fflush()
            next
        }
        /^[[:space:]]*$/ { next }
        { printf "FILE %s\n", $0; fflush() }
    '
}

case "${1:-}" in
    status)
        if mounted; then
            printf 'mounted=yes\n'
        else
            printf 'mounted=no\n'
        fi
        printf 'drive=%s\n' "$DRIVE"
        printf 'dest=%s\n' "$DEST"
        printf 'label=%s\n' "$LABEL"
        printf 'source=%s\n' "$SRC"
        if crypto_ok; then printf 'crypto=yes\n'; else printf 'crypto=no\n'; fi
        free="$(free_bytes 2>/dev/null)"
        printf 'free=%s\n' "${free:-0}"
        if [ -r "$STAMP" ]; then
            printf 'last=%s\n' "$(head -1 "$STAMP")"
        else
            printf 'last=\n'
        fi
        if [ -r "$DRIVE/last-size" ]; then
            printf 'size=%s\n' "$(head -1 "$DRIVE/last-size")"
        else
            printf 'size=0\n'
        fi
        ;;

    mount)
        mount_drive || die mount-failed "$DRIVE"
        step "Mounted $DRIVE"
        done_ok
        ;;

    backup)
        step "Checking the drive"
        mounted || mount_drive || die not-mounted "$DRIVE"
        crypto_ok || die not-encrypted "$(drive_device)"
        [ -d "$DEST" ] || mkdir -p "$DEST" || die no-dest "$DEST"

        printf 'PROGRESS 0 0 0\n'

        err="$(mktemp)"
        last="$(mktemp)"
        trap 'rm -f "$err" "$last"; printf "DONE cancelled\n"; exit 130' INT TERM

        step "Copying $SRC"
        rsync -aH --delete --numeric-ids --human-readable --no-specials \
              --info=progress2 --info=name --no-inc-recursive \
              --exclude=/lost+found \
              "$SRC/" "$DEST/" 2>"$err" | tr '\r' '\n' | parse_progress "$last"
        rc=${PIPESTATUS[0]}
        if [ "$rc" -ne 0 ] && [ "$rc" -ne 24 ]; then
            die rsync-failed "$(head -1 "$err" | tr -d '\n')"
        fi
        mirrored="$(tail -1 "$last" 2>/dev/null | cut -d' ' -f3)"

        step "Writing the system files"
        mkdir -p "$SYS"
        if [ -d /etc/nixriot ]; then
            rsync -a --delete /etc/nixriot/ "$SYS/nixriot/" 2>/dev/null
        fi
        {
            printf 'hostname %s\n' "$(hostname)"
            printf 'nixriot %s\n' "$(tr -d ' \n' < /etc/nixriot/VERSION 2>/dev/null || echo unknown)"
            printf 'nixos %s\n' "$(nixos-version 2>/dev/null || echo unknown)"
            printf 'date %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            printf 'source %s\n' "$SRC"
        } > "$SYS/MANIFEST"
        lsblk -f > "$SYS/lsblk.txt" 2>/dev/null
        blkid > "$SYS/blkid.txt" 2>/dev/null
        efibootmgr -v > "$SYS/efibootmgr.txt" 2>/dev/null
        cp /etc/fstab "$SYS/fstab" 2>/dev/null

        step "Verifying"
        drift="$(rsync -n -aH --delete --numeric-ids --itemize-changes \
                       --no-specials --exclude=/lost+found \
                       "$SRC/" "$DEST/" 2>/dev/null | awk '!/^\.d\.\.t/')"
        if [ -n "$drift" ]; then
            printf '%s\n' "$drift" | head -10 | while IFS= read -r l; do
                printf 'STEP drift %s\n' "$(printf '%s' "$l" | cut -c1-70)"
            done
            rm -f "$err" "$last"
            printf 'ERROR drift %s\n' "$(printf '%s\n' "$drift" | wc -l)"
            exit 1
        fi

        date -u +%Y-%m-%dT%H:%M:%SZ > "$STAMP"
        printf '%s\n' "${mirrored:-0}" > "$DRIVE/last-size"
        {
            printf '%s backup %s -> %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SRC" "$DEST"
            printf 'size %s\n' "${mirrored:-0}"
        } >> "$LOG"
        rm -f "$err" "$last"
        step "Verified"
        done_ok
        ;;

    verify)
        mounted || die not-mounted "$DRIVE"
        step "Comparing $SRC against $DEST"
        drift="$(rsync -n -aH --delete --numeric-ids --itemize-changes \
                       --no-specials --exclude=/lost+found \
                       "$SRC/" "$DEST/" 2>/dev/null | awk '!/^\.d\.\.t/')"
        if [ -n "$drift" ]; then
            printf '%s\n' "$drift" | head -10 | while IFS= read -r l; do
                printf 'STEP drift %s\n' "$(printf '%s' "$l" | cut -c1-70)"
            done
            printf 'ERROR drift %s\n' "$(printf '%s\n' "$drift" | wc -l)"
            exit 1
        fi
        done_ok
        ;;

    restore)
        mounted || die not-mounted "$DRIVE"
        [ -d "$DEST" ] || die no-backup "$DEST"
        if [ "$MODE" = dry ]; then
            step "Comparing $DEST against $SRC"
            drift="$(rsync -n -aH --numeric-ids --itemize-changes \
                           --no-specials \
                           "$DEST/" "$SRC/" 2>/dev/null | awk '!/^\.d\.\.t/')"
            printf '%s\n' "$drift" | head -20 | while IFS= read -r l; do
                [ -n "$l" ] && printf 'STEP would change %s\n' "$(printf '%s' "$l" | cut -c1-70)"
            done
            printf 'PROGRESS 100 0 0\n'
            done_ok
            exit 0
        fi

        step "Restoring $DEST into $SRC"
        err="$(mktemp)"
        trap 'rm -f "$err"; printf "DONE cancelled\n"; exit 130' INT TERM
        rsync -aH --numeric-ids --human-readable --no-specials \
              --info=progress2 --info=name --no-inc-recursive \
              "$DEST/" "$SRC/" 2>"$err" | tr '\r' '\n' | parse_progress
        rc=${PIPESTATUS[0]}
        if [ "$rc" -ne 0 ] && [ "$rc" -ne 24 ]; then
            die rsync-failed "$(head -1 "$err" | tr -d '\n')"
        fi
        rm -f "$err"
        step "Restore the system side: install NixRiot, then copy $SYS/nixriot over /etc/nixriot and rebuild"
        done_ok
        ;;

    *)
        printf 'usage: backup.sh status|mount|backup|verify|restore [--go] [DEST]\n' >&2
        exit 1
        ;;
esac
