#!/bin/bash
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")

for v in "${VERSIONS[@]}"; do
    file="instances/$v/server.js"
    if [ -f "$file" ]; then
        echo "Fixing $file..."
        python3 -c '
path = "'$file'"
with open(path, "r") as f:
    content = f.read()

# Fix broken app.listen line if present
content = content.replace("app.listen(PORT, \x270.0.0.0\x27) => {", "app.listen(PORT, \x270.0.0.0\x27, () => {")
content = content.replace("app.listen(PORT) => {", "app.listen(PORT, () => {")

with open(path, "w") as f:
    f.write(content)
'
        node --check "$file" && echo "  -> $file syntax OK!"
    fi
done

echo "[+] All servers fixed and verified!"
