#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="$HOME/request-runner"
cd "$APP"

echo "=== Request Runner® — Termux Android Fix ==="

# Stop leftover processes without killing the current shell
pkill -f "$APP/server.js" 2>/dev/null || true
pkill -f "next-server" 2>/dev/null || true

# Patch Next.js server configuration without Python
if grep -q 'const app = next({ dev });' server.js; then
    sed -i 's/const app = next({ dev });/const app = next({ dev, turbopack: false });/' server.js
fi

# Force the dev script to use Webpack on Android/ARM64
node -e '
const fs=require("fs");
const p="package.json";
const j=JSON.parse(fs.readFileSync(p,"utf8"));
j.scripts=j.scripts||{};
j.scripts.dev="next dev --webpack";
fs.writeFileSync(p,JSON.stringify(j,null,2)+"\n");
'

echo
echo "Checking configuration..."
grep -n "next(" server.js || true
grep -n '"dev"' package.json || true

if ! grep -q 'turbopack: false' server.js; then
    echo "ERROR: server.js patch failed."
    exit 1
fi

if ! grep -q 'next dev --webpack' package.json; then
    echo "ERROR: Webpack command was not configured."
    exit 1
fi

echo
echo "✓ Next.js Turbopack disabled"
echo "✓ Webpack forced"
echo "✓ Android ARM64 compatibility configured"
echo
echo "Starting Request Runner®..."
echo

exec npm run dev
