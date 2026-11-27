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
TEST="${NIXRIOT_BACKUP_TEST:-0}"
BWLIMIT="${NIXRIOT_BACKUP_BWLIMIT:-}"

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
die() {
    printf '%s %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "${2:-}" \
        >> "${HOME}/.config/panacea/backup-errors.log" 2>/dev/null || true
    printf 'ERROR %s %s\n' "$1" "${2:-}"
    exit 1
}

mounted() { findmnt -n -o SOURCE --mountpoint "$DRIVE" >/dev/null 2>&1; }

drive_device() { findmnt -n -o SOURCE --mountpoint "$DRIVE" 2>/dev/null; }

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

free_bytes() {
    mounted || { printf '0\n'; return 0; }
    df -B1 --output=avail "$DRIVE" 2>/dev/null | tail -1 | tr -d ' '
}

# One read-only scan of the source before the copy. Emits STEP Planning and
# PLAN, writes $SYS/manifest.txt, and refuses to start if the transfer will not
# fit. Sets PLAN_FILES, PLAN_BYTES, PLAN_DELETES and PLAN_FREE. Returns rsync's
# status so the caller can abort on a real failure.
plan_scan() {
    local raw hdr ver rc
    raw="$(mktemp)"
    hdr="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    ver="$(tr -d ' \n' < /etc/nixriot/VERSION 2>/dev/null || echo unknown)"
    mkdir -p "$SYS"

    step "Planning"
    rsync -n -aH --delete --numeric-ids --no-specials \
          --exclude=/lost+found --exclude=/.gvfs \
          --out-format='%n|%l' \
          "$SRC/" "$DEST/" 2>/dev/null > "$raw"
    rc=$?
    [ "$rc" -eq 24 ] && rc=0

    # rsync 3.5.0 prints "deleting name" for --delete with a plain out-format;
    # only --itemize-changes prints the "*deleting" form. Count both.
    read -r PLAN_FILES PLAN_BYTES PLAN_DELETES < <(awk -v man="$SYS/manifest.txt" \
        -v hdr="$hdr" -v host="$(hostname)" -v ver="$ver" '
        BEGIN {
            printf "# %s %s %s\n", hdr, host, ver > man
            files = 0; bytes = 0; del = 0
        }
        /^\*?deleting[[:space:]]/ { del++; next }
        $0 !~ /\|[0-9]+$/ { next }
        {
            n = $0
            sub(/\|[^|]*$/, "", n)          # path is everything before the last |
            if (n ~ /\/$/) next             # directories carry no payload
            sz = $0
            sub(/^.*\|/, "", sz)
            if (sz !~ /^[0-9]+$/) sz = 0
            files++; bytes += sz
            printf "%s|%s\n", n, sz > man
        }
        END { printf "%d %d %d\n", files, bytes, del }
    ' "$raw")
    rm -f "$raw"

    PLAN_FREE="$(free_bytes)"
    printf 'PLAN files=%s bytes=%s deletes=%s free=%s\n' \
           "${PLAN_FILES:-0}" "${PLAN_BYTES:-0}" \
           "${PLAN_DELETES:-0}" "${PLAN_FREE:-0}"

    if [ "$TEST" != 1 ] \
       && [ "${PLAN_BYTES:-0}" -gt "$(( ${PLAN_FREE:-0} - 512 * 1024 * 1024 ))" ]; then
        die no-space "${PLAN_BYTES:-0} ${PLAN_FREE:-0}"
    fi
    return "$rc"
}

verify_plan() {
    local names="${1:-}" man="$SYS/manifest.txt"
    local miss=0 changed=0 skipped=0 sent=0 checked=0 p sz d have

    if [ -n "$names" ] && [ -s "$names" ]; then
        while IFS= read -r p; do
            [ -n "$p" ] || continue
            case "$p" in */) continue ;; esac
            case "$p" in ./*) p="${p#./}" ;; esac
            sent=$((sent + 1))
            d="$DEST/$p"
            if [ ! -f "$d" ]; then miss=$((miss + 1)); continue; fi
            have=$(stat -c %s "$d" 2>/dev/null || echo 0)
            [ "$have" -eq 0 ] && miss=$((miss + 1))
        done < "$names"
    fi

    if [ -r "$man" ]; then
        while IFS='|' read -r p sz; do
            case "$p" in \#*|"") continue ;; esac
            checked=$((checked + 1))
            d="$DEST/$p"
            if [ ! -e "$d" ]; then skipped=$((skipped + 1)); continue; fi
            [ -f "$d" ] || continue
            have=$(stat -c %s "$d" 2>/dev/null || echo 0)
            [ "$have" -ne "$sz" ] && changed=$((changed + 1))
        done < "$man"
    fi

    printf 'STEP sent %s files, %s changed, %s of %s not copied\n' \
           "$sent" "$changed" "$skipped" "$checked"
    if [ "$miss" -gt 0 ]; then
        printf 'ERROR verify-missing %s\n' "$miss"
        return 1
    fi
    return 0
}

parse_progress() {
    awk -v out="${1:-/dev/null}" -v planned="${2:-0}" -v names="${3:-}" '
        # rsync --human-readable writes the byte count as 52.43M / 32.77K /
        # 1.23G / 0, so the old "digits and commas only" match never fired and
        # every progress line was mistaken for a FILE. Turn a human size into
        # bytes instead.
        function tobytes(s,   n, u) {
            u = ""
            if (match(s, /[A-Za-z]+$/)) {
                u = substr(s, RSTART, RLENGTH)
                s = substr(s, 1, RSTART - 1)
            }
            gsub(",", "", s)
            n = s + 0
            u = toupper(u)
            if      (u == "K") n *= 1024
            else if (u == "M") n *= 1024 * 1024
            else if (u == "G") n *= 1024 * 1024 * 1024
            else if (u == "T") n *= 1024 * 1024 * 1024 * 1024
            return n
        }
        {
            # A progress line is a size field, a percentage field, a rate and a
            # time; the percentage is whichever field ends in %.
            p = ""
            if (NF >= 4 && $1 ~ /^[0-9]/)
                for (i = 1; i <= NF; i++)
                    if ($i ~ /%$/) { p = $i; gsub("%", "", p); break }
            if (p != "") {
                b = int(tobytes($1))
                pn = int(p)
                # Prefer the planned transfer size so the numbers agree with
                # PLAN; fall back to the value back-computed from the rsync
                # percentage when there was no plan.
                t = planned > 0 ? planned : (pn > 0 ? int(b * 100 / pn) : 0)
                printf "PROGRESS %d %d %d\n", pn, b, t
                print pn, b, t > out
                close(out)
                fflush()
                next
            }
            if ($0 ~ /^[[:space:]]*$/) next
            printf "FILE %s\n", $0
            if (names != "") { print $0 > names; close(names) }
            fflush()
        }
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
        if [ "$TEST" != 1 ]; then
            mounted || mount_drive || die not-mounted "$DRIVE"
            crypto_ok || die not-encrypted "$(drive_device)"
        fi
        [ -d "$DEST" ] || mkdir -p "$DEST" || die no-dest "$DEST"

        plan_scan
        prc=$?
        [ "$prc" -eq 0 ] || [ "$prc" -eq 24 ] || die rsync-failed "planning pass"

        printf 'PROGRESS 0 0 0\n'

        err="$(mktemp)"
        last="$(mktemp)"
        sent_list="$(mktemp)"
        trap 'pkill -TERM -P $$ 2>/dev/null; rm -f "$err" "$last" "$sent_list"; printf "DONE cancelled\n"; exit 130' INT TERM

        step "Copying $SRC"
        rsync -aH --delete --numeric-ids --human-readable --no-specials \
              --info=progress2 --info=name --no-inc-recursive \
              --exclude=/lost+found --exclude=/.gvfs \
              ${BWLIMIT:+--bwlimit="$BWLIMIT"} \
              "$SRC/" "$DEST/" 2>"$err" | tr '\r' '\n' | parse_progress "$last" "${PLAN_BYTES:-0}" "$sent_list"
        rc=${PIPESTATUS[0]}
        if [ "$rc" -ne 0 ] && [ "$rc" -ne 24 ]; then
            die rsync-failed "$(head -1 "$err" | tr -d '\n')"
        fi
        mirrored="$(tail -1 "$last" 2>/dev/null | cut -d' ' -f2)"

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
        verify_plan || { rm -f "$err" "$last"; exit 1; }

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
        plan_scan || die rsync-failed "planning pass"
        step "Verifying"
        verify_plan || exit 1
        done_ok
        ;;

    restore)
        mounted || die not-mounted "$DRIVE"
        [ -d "$DEST" ] || die no-backup "$DEST"
        if [ "$MODE" = dry ]; then
            step "Comparing $DEST against $SRC"
            drift="$(rsync -n -aH --numeric-ids --itemize-changes \
                           --no-specials \
                           --exclude=/.gvfs \
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
        trap 'pkill -TERM -P $$ 2>/dev/null; rm -f "$err"; printf "DONE cancelled\n"; exit 130' INT TERM
        rsync -aH --numeric-ids --human-readable --no-specials \
              --info=progress2 --info=name --no-inc-recursive \
              --exclude=/.gvfs \
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
