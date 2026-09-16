#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "🚀 [UI Launcher] Starting client development server..."

if [ -d "client" ]; then
    cd client
    npm run dev -- --host 0.0.0.0
else
    npm run dev -- --host 0.0.0.0
fi
