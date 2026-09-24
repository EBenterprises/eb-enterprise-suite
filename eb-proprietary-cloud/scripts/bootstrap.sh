#!/bin/bash
set -e

echo "[*] Initializing proprietary cloud node environment..."
sudo apt-get update && sudo apt-get install -y docker.io git curl

sudo systemctl enable docker
sudo systemctl start docker

echo "[*] Setting up proprietary application directories..."
sudo mkdir -p /opt/proprietary-app/data
sudo chmod 755 /opt/proprietary-app

echo "[*] Bootstrap complete. Ready for deployment sync."
