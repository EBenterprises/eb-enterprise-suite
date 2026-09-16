#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="$HOME/request-runner"
ZIP="request-runner-app.zip"

echo "=== Request Runner® — One-Step Launcher ==="

# Storage permission
termux-setup-storage 2>/dev/null || true
sleep 2

# Find the ZIP wherever Android exposed it
ZIP_PATH="$(find \
  "$HOME/storage" \
  /sdcard \
  /storage/emulated/0 \
  "$HOME/downloads" \
  -type f \
  -iname "$ZIP" 2>/dev/null | head -n 1)"

if [ -z "$ZIP_PATH" ]; then
  echo
  echo "ERROR: $ZIP was not found."
  echo
  echo "Checking accessible downloads:"
  find "$HOME/storage" /sdcard /storage/emulated/0 "$HOME/downloads" \
    -maxdepth 3 -type f 2>/dev/null | head -100
  echo
  echo "Put request-runner-app.zip in your Android Download folder, then run:"
  echo "bash ~/launch-request-runner.sh"
  exit 1
fi

echo "Found: $ZIP_PATH"

# Install required packages only if missing
command -v node >/dev/null 2>&1 || pkg install nodejs-lts -y
command -v unzip >/dev/null 2>&1 || pkg install unzip -y

# Fresh isolated application directory
mkdir -p "$APP"

# Extract without touching the rest of Termux
unzip -o "$ZIP_PATH" -d "$APP"

cd "$APP"

echo
echo "Installing Request Runner® dependencies..."
npm install

echo
echo "========================================"
echo " Request Runner® READY"
echo "========================================"
echo
echo "Customer:"
echo "http://127.0.0.1:3000/request"
echo
echo "Operations:"
echo "http://127.0.0.1:3000/ops"
echo
echo "Starting server..."
echo

exec npm run dev
