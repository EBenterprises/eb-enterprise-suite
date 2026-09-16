#!/bin/bash
PORT="${1:-8080}"
echo "[+] Launching background public domain daemon..."
nohup ./start_public_tunnel.sh "$PORT" > tunnel.log 2>&1 &
echo "[+] Public tunnel daemon active in background!"
echo "    -> View logs with: cat tunnel.log"
