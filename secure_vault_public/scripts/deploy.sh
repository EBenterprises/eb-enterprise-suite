#!/usr/bin/env bash
# EB Enterprises Monolith Deployment Script

echo "[*] Setting up directory structure..."
mkdir -p data scripts

echo "[*] Installing dependencies..."
pip install -r requirements.txt

echo "[*] Launching monolithic secure vault daemon on port 5001..."
python app.py &
echo "[SUCCESS] Secure Monolith Architecture active."
