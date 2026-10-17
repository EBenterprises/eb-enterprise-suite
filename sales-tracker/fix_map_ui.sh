#!/usr/bin/env bash
set -euo pipefail

echo "=== Searching for index.html files containing map or 1.75g ==="
grep -rn "1.75g" . --exclude-dir=node_modules || true
grep -rn "map" . --exclude-dir=node_modules --include="*.html" || true

# Find the index.html that actually has the map/1.75g
CORRECT_HTML=""
for f in $(find . -name "index.html" -not -path "*/node_modules/*"); do
    if grep -q -E "1.75g|map|Leaflet|leaflet" "$f" 2>/dev/null; then
        CORRECT_HTML="$f"
        echo "Found matching UI at: $CORRECT_HTML"
        break
    fi
done

if [ -n "$CORRECT_HTML" ]; then
    echo "Copying $CORRECT_HTML to active v4 public directory / root..."
    mkdir -p v4/public public instances/v4/public
    cp "$CORRECT_HTML" v4/public/index.html
    cp "$CORRECT_HTML" public/index.html
    cp "$CORRECT_HTML" instances/v4/public/index.html 2>/dev/null || true
    cp "$CORRECT_HTML" index.html 2>/dev/null || true
    echo "UI successfully synchronized across all target paths!"
else
    echo "Checking git history for the map index.html..."
    git log --all -S "1.75g" --oneline
fi
