#!/data/data/com.termux/files/usr/bin/bash

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1

BUILD_SCRIPT="$(node -e '
const p=require("./package.json");
process.stdout.write(p.scripts?.build || "");
')"

if [ "$BUILD_SCRIPT" != "next build --webpack" ]; then
    echo "[RUNTIME] FAIL: package build script is:"
    echo "[RUNTIME] $BUILD_SCRIPT"
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "[RUNTIME] FAIL: npm unavailable"
    exit 1
fi

if [ ! -x node_modules/.bin/next ]; then
    echo "[RUNTIME] FAIL: local Next executable missing"
    exit 1
fi

echo "[RUNTIME] npm: $(command -v npm)"
echo "[RUNTIME] Next: node_modules/.bin/next"
echo "[RUNTIME] Build: $BUILD_SCRIPT"
echo "[RUNTIME] Engine: webpack"
echo "[RUNTIME] PASS"
