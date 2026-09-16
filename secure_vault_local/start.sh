#!/bin/bash
echo "[+] Clearing any lingering python instances..."
pkill -f app.py || true

echo "[+] Starting Secure Vault on port 5001..."
export FLASK_APP=app/app.py
export FLASK_DEBUG=1
python3 secure_vault/app/app.py || python3 app/app.py
