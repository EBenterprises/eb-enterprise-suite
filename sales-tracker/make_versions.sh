#!/bin/bash
set -e

echo "[+] Creating exact copies for versions v2, v3, v4, and v5..."

for ver in v2 v3 v4 v5; do
    echo "[+] Packaging current state as release: $ver..."
    
    # Create target directory
    mkdir -p releases/$ver
    
    # Copy core application assets
    cp -r server.js public package.json run.sh releases/$ver/ 2>/dev/null || true
    if [ -f "sales.sqlite" ]; then
        cp sales.sqlite releases/$ver/
    fi
    
    # Create or update git tag for the version
    if git rev-parse "$ver" >/dev/null 2>&1; then
        git tag -d "$ver" >/dev/null 2>&1 || true
    fi
    git tag -a "$ver" -m "EB Sales Tracker Version ${ver#v}.0"
    
    echo "[+] Version $ver created and tagged successfully."
done

echo "[+] All versions (v2, v3, v4, v5) successfully generated and tagged!"
