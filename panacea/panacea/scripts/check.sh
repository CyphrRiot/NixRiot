#!/bin/bash
# Syntax check for the pill's QML, before it ever runs.
#
# A typo in QML takes the whole shell down, and finding that out on a live
# system, having lost the panel, is unpleasant. qmllint reads the files without
# running them.
#
# Only syntax is checked. Deep mode (-U) is useless here: the Quickshell types
# are not in qmltypes and it reports hundreds of "Process was not found", in
# which noise the real error is lost.
#
# qmllint from Qt 6.11.1 reports an error only through its exit code: it no
# longer prints a line or a message (6.9 did). So the script names the file and
# leaves the line to the shell itself; `qs -c panacea` will print it with a
# position.
#
#   check.sh            check ~/.config/panacea
#   check.sh DIR        check another directory
#
# Two files Qt 6.11 cannot handle at all: qmllint and qmlformat stumble over the
# annotation `function foo(): void`, even though it is legal and required.
# Without the type Quickshell does not expose the function, and every Hyprland
# binding travels over IPC. That is a bug in the tools, not in the code, so such
# files are skipped with an explicit note rather than rewritten for the parser.

set -u

DIR="${1:-$HOME/.config/panacea}"
cd "$DIR" 2>/dev/null || { echo "no such directory: $DIR" >&2; exit 2; }
command -v qmllint >/dev/null || { echo "qmllint is not installed" >&2; exit 2; }

skipped=()
failed=()

shopt -s nullglob
for f in *.qml; do
    # `): void` and `): var` are what the Qt 6.11 parser trips on
    if grep -qE '\):[[:space:]]*(void|var)\b' "$f"; then
        skipped+=("$f")
        continue
    fi
    # exit 0 is clean, 1 means warnings, 2 means errors
    qmllint "$f" >/dev/null 2>&1
    [ "$?" -ge 2 ] && failed+=("$f")
done

if [ "${#failed[@]}" -gt 0 ]; then
    echo "qml syntax errors in:"
    printf '  %s\n' "${failed[@]}"
    rc=1
else
    echo "✓ syntax is clean"
    rc=0
fi

if [ "${#skipped[@]}" -gt 0 ]; then
    printf '· skipped (Qt cannot parse ": void"): %s\n' "${skipped[*]}"
fi

exit $rc
