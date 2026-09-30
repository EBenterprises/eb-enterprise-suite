#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd "$HOME/sales-tracker"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="start_cluster.sh.bak-ports-$STAMP"

echo "=== BACKUP ==="
cp start_cluster.sh "$BACKUP"
echo "GREEN: $BACKUP"

echo
echo "=== PATCHING CLUSTER LAUNCHER ==="
python3 - <<'PY'
from pathlib import Path

p = Path("start_cluster.sh")
s = p.read_text()

old = 'PORTS=(3000 3001 3002 3003 3004)'
new = 'PORTS=(3100 3101 3102 3103 3104)'

if old not in s:
    raise SystemExit("RED: Expected PORTS declaration not found")

s = s.replace(old, new, 1)
p.write_text(s)
PY

chmod +x start_cluster.sh
echo "GREEN: launcher now targets 3100-3104"

echo
echo "=== VERIFY LAUNCHER ==="
grep -nE 'PORTS=|PORT="\$p"' start_cluster.sh

echo
echo "=== SYNTAX CHECKS ==="
bash -n start_cluster.sh
for v in v1 v2 v3 v4 v5; do
    node --check "instances/$v/server.js"
done
echo "GREEN: launcher + v1-v5 syntax clean"

echo
echo "=== STOPPING SALES TRACKER ==="
pkill -9 -f "$HOME/sales-tracker/instances/.*/server.js" 2>/dev/null || true
sleep 1

echo
echo "=== STARTING SALES TRACKER ON DEDICATED PORTS ==="
LOGFILE="$HOME/sales-tracker/sales-tracker-start.log"
./start_cluster.sh > "$LOGFILE" 2>&1 || {
    cat "$LOGFILE"
    exit 1
}

cat "$LOGFILE"

echo
echo "=== WAITING FOR READINESS ==="
READY=0

for attempt in {1..10}; do
    OK=0
    for port in 3100 3101 3102 3103 3104; do
        code="$(curl -s -o /dev/null -w '%{http_code}' \
            --connect-timeout 1 \
            --max-time 2 \
            "http://127.0.0.1:$port/" || true)"

        [ "$code" = "200" ] && OK=$((OK + 1))
    done

    echo "Attempt $attempt: $OK/5 ready"

    if [ "$OK" -eq 5 ]; then
        READY=1
        break
    fi

    sleep 1
done

echo
echo "=== FINAL SALES TRACKER CHECK ==="

if [ "$READY" -ne 1 ]; then
    echo "RED: Not all Sales Tracker instances became ready"
    exit 1
fi

for port in 3100 3101 3102 3103 3104; do
    code="$(curl -s -o /dev/null -w '%{http_code}' \
        --connect-timeout 2 \
        --max-time 3 \
        "http://127.0.0.1:$port/" || true)"

    if [ "$code" = "200" ]; then
        echo "GREEN :$port -> HTTP $code"
    else
        echo "RED   :$port -> HTTP $code"
    fi
done

echo
echo "=== APP IDENTITY CHECK ==="

for port in 3100 3101 3102 3103 3104; do
    body="$(curl -s --connect-timeout 2 --max-time 3 \
        "http://127.0.0.1:$port/" || true)"

    if printf '%s' "$body" | grep -qiE 'Ledger Suite|Sales Tracker|EB Sales|EB Enterprises'; then
        echo "GREEN :$port -> Sales Tracker markers detected"
    else
        echo "RED   :$port -> Sales Tracker markers NOT detected"
    fi
done

echo
echo "=== OLD PORT CHECK ==="

OLD_BUSY=0

for port in 3000 3001 3002 3003 3004; do
    code="$(curl -s -o /dev/null -w '%{http_code}' \
        --connect-timeout 1 \
        --max-time 2 \
        "http://127.0.0.1:$port/" || true)"

    if [ "$code" = "000" ]; then
        echo "GREEN :$port -> no HTTP service"
    else
        echo "INFO  :$port -> HTTP $code (another application may own this port)"
        OLD_BUSY=1
    fi
done

echo
echo "=== SALES TRACKER PROCESSES ==="
ps -ef | grep '[n]ode.*server.js' || true

echo
echo "=== FINAL PORT MAP ==="
echo "v1 -> http://127.0.0.1:3100/"
echo "v2 -> http://127.0.0.1:3101/"
echo "v3 -> http://127.0.0.1:3102/"
echo "v4 -> http://127.0.0.1:3103/"
echo "v5 -> http://127.0.0.1:3104/"

echo
echo "=== RESULT ==="
echo "GREEN: Sales Tracker cluster is running on dedicated ports 3100-3104."

if [ "$OLD_BUSY" -eq 1 ]; then
    echo "INFO: One or more old 3000-3004 ports remain occupied by another service."
    echo "      They were NOT killed because they may belong to EggFinder."
fi
