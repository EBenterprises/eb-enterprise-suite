#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Dynamic URL Discovery & Opener
# ==============================================================================
set -e

echo "[+] Scanning project directory for all configured ports..."

# Dynamically extract all port numbers assigned to app.listen() across the entire project
PORTS=$(grep -hr "listen(" . 2>/dev/null | grep -oE '[0-9]{4}' | sort -u || true)

if [ -z "$PORTS" ]; then
    echo "[!] No local ports discovered in project files."
    
    # Fallback to defaults if grep fails
    PORTS="3000 3001 3002 3003 3004"
    echo "[+] Falling back to default range: $PORTS"
else
    echo "[+] Discovered ports: $(echo $PORTS | tr '\n' ' ')"
fi

for port in $PORTS; do
    URL="http://localhost:$port"
    echo "[+] Dispatching: $URL"
    
    if command -v termux-open-url &> /dev/null; then
        termux-open-url "$URL"
    elif command -v am &> /dev/null; then
        am start -a android.intent.action.VIEW -d "$URL" > /dev/null 2>&1
    else
        echo "    -> API missing. Open manually: $URL"
    fi
    sleep 0.5
done

echo "[+] All discovered URLs have been launched."
