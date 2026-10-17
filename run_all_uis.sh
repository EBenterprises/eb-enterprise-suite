#!/usr/bin/env bash

echo "=== SCANNING & STARTING ALL AVAILABLE SERVERS & UIs ==="

# Find all server scripts and start them or list them clearly
find . -type f \( -name "server.js" -o -name "server.py" -o -name "app.py" \) -not -path "*/node_modules/*" -not -path "*/.*" | while read -r server; do
    echo "Found server: $server"
    DIR=$(dirname "$server")
    echo "Entering $DIR and checking package..."
    if [ -f "$DIR/package.json" ]; then
        (cd "$DIR" && npm install --silent 2>/dev/null && node server.js &)
    elif [[ "$server" == *.py ]]; then
        (cd "$DIR" && python3 "$(basename "$server")" &)
    else
        (cd "$DIR" && node "$(basename "$server")" &)
    fi
done

echo "=== ALL UI AND BACKEND SERVICES LAUNCHED ==="
ps aux | grep -E "node|python"
