#!/usr/bin/env bash
set -euo pipefail

echo "==> Inspecting working tree and identifying executable entry points..."

# Look for standard entry points (package.json, Makefile, main scripts, etc.)
if [ -f "package.json" ]; then
  echo "Found Node.js project. Installing dependencies and launching..."
  npm install
  if npm run | grep -q "start"; then
    npm run start
  elif npm run | grep -q "dev"; then
    npm run dev
  else
    node index.js || echo "Please check package.json main entry point."
  fi
elif [ -f "Makefile" ]; then
  echo "Found Makefile. Running make..."
  make
elif [ -f "main.py" ] || [ -f "app.py" ]; then
  MAIN_PY=$([ -f "app.py" ] && echo "app.py" || echo "main.py")
  echo "Found Python application ($MAIN_PY). Launching..."
  python3 "$MAIN_PY"
else
  echo "==> Listing root directory contents to locate runnable components:"
  ls -la
  echo "Please select the appropriate entry point script or binary above to execute."
fi
