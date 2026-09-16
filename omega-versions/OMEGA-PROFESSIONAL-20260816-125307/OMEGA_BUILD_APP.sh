#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "============================================================"
echo "              OMEGA® — APPLICATION BUILD"
echo "============================================================"
echo

# Do not create another verification gate.
# Do not modify certified artifacts.
# Build the actual Next.js application.

test -f package.json || {
    echo "FAIL — package.json missing"
    exit 1
}

test -d src/app || {
    echo "FAIL — src/app missing"
    exit 1
}

echo "=== BUILD ==="
npm run build

echo
echo "============================================================"
echo "OMEGA® APPLICATION BUILD COMPLETE"
echo "============================================================"
echo
echo "Start the application with:"
echo
echo "npm run dev -- --hostname 0.0.0.0"
