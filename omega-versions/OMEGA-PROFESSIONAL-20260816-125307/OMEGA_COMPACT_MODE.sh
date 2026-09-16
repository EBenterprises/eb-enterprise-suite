#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

export NPM_CONFIG_LOGLEVEL=error
export NEXT_TELEMETRY_DISABLED=1

exec 3>&1
exec 4>&2

# Suppress normal command output.
quiet() {
    local label="$1"
    shift
    local log
    log="$(mktemp)"

    if "$@" >"$log" 2>&1; then
        rm -f "$log"
        printf '✓ %-24s\n' "$label" >&3
    else
        printf '✗ %-24s\n' "$label" >&3
        tail -20 "$log" >&4
        rm -f "$log"
        return 1
    fi
}

echo
echo "OMEGA® COMPACT"
echo "───────────────"

quiet "Filesystem" bash -c '
    test -s package.json &&
    test -s package-lock.json &&
    test -s bin/omega.js &&
    test -d src &&
    test -d data
'

quiet "CLI" node bin/omega.js status
quiet "CLI capabilities" node bin/omega.js capabilities

if [ -s .next/BUILD_ID ]; then
    printf '✓ %-24s\n' "Production artifact"
else
    printf '• %-24s\n' "Production artifact pending"
fi

if [ -s .omega/certification/OMEGA_CERTIFIED.txt ]; then
    printf '✓ %-24s\n' "Certification"
else
    printf '• %-24s\n' "Not certified"
fi

if curl -fsS http://127.0.0.1:3000 >/dev/null 2>&1; then
    printf '✓ %-24s\n' "Runtime HTTP 200"
else
    printf '• %-24s\n' "Runtime offline"
fi

echo "STATUS: COMPACT"
