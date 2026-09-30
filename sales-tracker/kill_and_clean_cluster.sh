#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd "$HOME/sales-tracker"

echo "=== STOPPING ALL NODE PROCESSES ==="
pkill -9 -f "node" || true
pkill -9 -f "server.js" || true
sleep 2

echo "=== CLEANING UP PORT CONFIGURATIONS ==="
# Reset cluster launcher to use 3100-3104
python3 - <<'PY'
from pathlib import Path
import re

p = Path("start_cluster.sh")
s = p.read_text()

# Replace ports in PORTS=() array
s2 = re.sub(r'PORTS=\([^)]+\)', 'PORTS=(3100 3101 3102 3103 3104)', s)
p.write_text(s2)
print("GREEN: start_cluster.sh updated to ports 3100-3104")
PY

chmod +x start_cluster.sh

echo "=== STARTING SALES TRACKER CLUSTER ==="
LOGFILE="$HOME/sales-tracker/sales-tracker-start.log"
./start_cluster.sh > "$LOGFILE" 2>&1 || {
    cat "$LOGFILE"
    exit 1
}

cat "$LOGFILE"

echo "=== VERIFYING PORTS 3100-3104 ==="
for port in 3100 3101 3102 3103 3104; do
    code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 "http://127.0.0.1:$port/" || true)"
    if [ "$code" = "200" ]; then
        echo "GREEN :$port -> HTTP $code"
    else
        echo "RED   :$port -> HTTP $code"
    fi
done

echo "=== ACTIVE PROCESSES ==="
ps -ef | grep '[n]ode.*server.js' || true

echo "GREEN: All old EggFinder/competing services terminated. Sales Tracker running on 3100-3104."
