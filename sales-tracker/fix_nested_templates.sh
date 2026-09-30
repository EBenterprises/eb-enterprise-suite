#!/bin/bash
set -euo pipefail

for v in v1 v2 v3 v4 v5; do
    file="instances/$v/server.js"

    echo "=== Fixing $v ==="

    cp "$file" "$file.bak-nested-$(date +%Y%m%d-%H%M%S)"

    python3 - "$file" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
s = path.read_text()

start = s.find("        function switchTab(tab) {")
if start == -1:
    raise SystemExit(f"switchTab not found: {path}")

# Find the server-side closing of the outer HTML template.
end_marker = "    </html>\n    `);"
end = s.find(end_marker, start)

if end == -1:
    raise SystemExit(f"Outer HTML template closing not found: {path}")

client = s[start:end]

# The entire HTML response is itself a JavaScript template literal.
# Escape nested client-side template literals and their ${...} expressions
# so they survive into the browser unchanged.
client = client.replace("\\", "\\\\")
client = client.replace("`", "\\`")
client = client.replace("${", "\\${")

# Restore the client portion while retaining the existing HTML closure.
s = s[:start] + client + s[end:]

path.write_text(s)
PY

    node --check "$file"
    echo "[PASS] $file"
done

echo
echo "=== ALL SYNTAX CHECKS ==="
for v in v1 v2 v3 v4 v5; do
    printf "%s: " "$v"
    node --check "instances/$v/server.js" && echo "PASS"
done
