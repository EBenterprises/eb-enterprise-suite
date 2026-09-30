#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd "$HOME/sales-tracker"

echo "=== BACKING UP ==="
STAMP="$(date +%Y%m%d-%H%M%S)"

for v in v1 v2 v3 v4 v5; do
    cp "instances/$v/server.js" "instances/$v/server.js.bak-ports-$STAMP"
done

echo "=== STOPPING SALES TRACKER INSTANCES ==="
pkill -f 'sales-tracker/instances/.*/server.js' 2>/dev/null || true
sleep 1

echo "=== ASSIGNING DEDICATED PORTS ==="

for spec in \
    "v1:3100" \
    "v2:3101" \
    "v3:3102" \
    "v4:3103" \
    "v5:3104"
do
    v="${spec%%:*}"
    port="${spec##*:}"

    python3 - "$v" "$port" <<'PY'
from pathlib import Path
import sys
import re

version = sys.argv[1]
port = sys.argv[2]
p = Path("instances") / version / "server.js"

s = p.read_text()

s2, n = re.subn(
    r"const PORT = process\.env\.PORT \|\| \d+;",
    f"const PORT = process.env.PORT || {port};",
    s,
    count=1
)

if n != 1:
    raise SystemExit(f"Could not update PORT in {p}")

p.write_text(s2)
print(f"{version} -> {port}")
PY

    node --check "instances/$v/server.js"
done

echo
echo "=== VERIFYING SERVER PORT DECLARATIONS ==="
grep -nE 'const PORT =' instances/v{1,2,3,4,5}/server.js

echo
echo "=== CHECKING OLD PORTS ==="
for port in 3000 3001 3002 3003 3004; do
    code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 "http://127.0.0.1:$port/" || true)"
    echo ":$port -> HTTP $code"
done

echo
echo "=== STARTING SALES TRACKER ==="
./start_cluster.sh

echo
echo "=== VERIFYING NEW PORTS ==="
sleep 2

for port in 3100 3101 3102 3103 3104; do
    code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 "http://127.0.0.1:$port/" || true)"

    if [ "$code" = "200" ]; then
        echo "GREEN :$port HTTP $code"
    else
        echo "RED   :$port HTTP $code"
    fi
done

echo
echo "=== INSTANCE/PID CHECK ==="
ps -ef | grep '[n]ode.*server.js' || true

echo
echo "=== FINAL URLS ==="
echo "v1: http://127.0.0.1:3100/"
echo "v2: http://127.0.0.1:3101/"
echo "v3: http://127.0.0.1:3102/"
echo "v4: http://127.0.0.1:3103/"
echo "v5: http://127.0.0.1:3104/"
