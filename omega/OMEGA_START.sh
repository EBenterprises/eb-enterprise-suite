#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd "$HOME/omega"

if ! command -v node >/dev/null 2>&1; then
    echo "Node.js is missing."
    echo "Run:"
    echo "pkg install nodejs"
    exit 1
fi

npm test

clear

echo "╔══════════════════════════════════════════════════╗"
echo "║                  O M E G A ®                    ║"
echo "║          ADAPTIVE APPLICATION ENGINE             ║"
echo "╚══════════════════════════════════════════════════╝"
echo
echo "Starting UI..."
echo

exec node server.js
