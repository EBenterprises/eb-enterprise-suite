#!/bin/bash
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")

for v in "${VERSIONS[@]}"; do
    file="instances/$v/server.js"
    if [ -f "$file" ]; then
        echo "Cleaning and fixing $file..."
        python3 -c '
path = "'$file'"
with open(path, "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if "app.listen" in line:
        # Rebuild a clean app.listen line
        new_lines.append("app.listen(PORT, \"0.0.0.0\", () => {\n")
        new_lines.append("    console.log(\"Server running on port \" + PORT);\n")
        new_lines.append("});\n")
    else:
        new_lines.append(line)

with open(path, "w") as f:
    f.writelines(new_lines)
'
        node --check "$file" && echo "  -> $file syntax OK!"
    fi
done

echo "[+] All servers successfully repaired and verified!"
