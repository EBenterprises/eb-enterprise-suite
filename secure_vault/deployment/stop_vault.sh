#!/bin/bash
cd ~/secure_vault

# Terminate running Flask application
pkill -f "python3 src/app.py" 2>/dev/null || true
echo "[-] Secure Vault stopped."
