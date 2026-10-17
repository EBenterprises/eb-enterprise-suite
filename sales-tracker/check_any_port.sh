#!/usr/bin/env bash
set -uo pipefail

echo "=== Checking active Node PIDs and Ports ==="
ps -ef | grep '[n]ode'

echo -e "\n=== Checking all listening TCP ports via ss / netstat / lsof ==="
if command -v ss &>/dev/null; then
    ss -tlnp || ss -tln
elif command -v netstat &>/dev/null; then
    netstat -tlnp || netstat -tln
elif command -v lsof &>/dev/null; then
    lsof -i -P -n | grep LISTEN
else
    echo "Scanning ports 3000 to 3200..."
    for p in $(seq 3000 3200); do
        if (echo >/dev/tcp/127.0.0.1/"$p") 2>/dev/null; then
            echo "Port $p is OPEN/LISTENING"
        fi
    done
fi
