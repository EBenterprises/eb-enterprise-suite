#!/bin/bash
set -e
echo "[*] Cleaning previous builds..."
buildozer clean || true
echo "[*] Triggering compilation pipeline..."
buildozer -v android debug
echo "[*] APK Generation Complete!"
ls -lh bin/
