#!/bin/bash
cd ~/secure_vault

# Clean up any lingering python instances
pkill -f "python3 src/app.py" 2>/dev/null || true
sleep 1

# Launch Flask application in the background with logging
python3 src/app.py > vault_runtime.log 2>&1 &
VAULT_PID=$!

echo "[+] Secure Vault started (PID: $VAULT_PID)"
echo "[+] Opening interface in browser..."

# Open via Termux intent utility
termux-open-url http://127.0.0.1:5001
