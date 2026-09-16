#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"
echo "[*] Working directory: $(pwd)"

if [ ! -d "venv" ]; then
    echo "[*] Initializing Python virtual environment with system site-packages..."
    python3 -m venv --system-site-packages venv
fi

echo "[*] Activating virtual environment..."
source venv/bin/activate

echo "[*] Ensuring build dependencies are present..."
pip install --upgrade pip setuptools wheel > /dev/null 2>&1

echo "[*] Installing/upgrading project requirements..."
pip install -r requirements.txt

echo "[*] Triggering live server daemon on http://localhost:5000..."
python3 src/app.py
