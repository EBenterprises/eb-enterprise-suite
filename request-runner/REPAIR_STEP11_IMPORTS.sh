#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/request-runner"
cd "$ROOT"

RUNTIME="$ROOT/.runtime"
BACKUP="$ROOT/.backups/step11-import-fix-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUNTIME" "$BACKUP"

ROUTE='app/api/requests/[id]/accept/route.js'

echo "=== REQUEST RUNNER® — STEP 11 IMPORT REPAIR ==="
echo

echo "[1] BACKUP"
cp "$ROUTE" "$BACKUP/route.js"
echo "✓ Backup created"

echo "[2] FIX RELATIVE IMPORTS"

python3 - "$ROUTE" <<'PY'
import sys
p = sys.argv[1]

s = open(p, "r", encoding="utf-8").read()

s = s.replace(
    'require("../../../../../../api/domain-service")',
    'require("../../../../../api/domain-service")'
)

s = s.replace(
    'require("../../../../../../api/store")',
    'require("../../../../../api/store")'
)

open(p, "w", encoding="utf-8").write(s)
PY

grep -n 'require' "$ROUTE"
echo "✓ Import paths corrected"

echo "[3] SYNTAX"
node --check "$ROUTE"
node --check api/domain-service.js
node --check api/store.js
echo "✓ Syntax valid"

echo "[4] STOP BROKEN NEXT"
pkill -f 'next-server' 2>/dev/null || true
pkill -f 'next dev --webpack' 2>/dev/null || true
sleep 2

echo "[5] START NEXT"
nohup npm run dev > "$RUNTIME/next.log" 2>&1 &
echo $! > "$RUNTIME/next.pid"

echo "[6] WAIT FOR API"

READY=0

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    if curl -fsS http://127.0.0.1:3000/api/health >/dev/null 2>&1; then
        READY=1
        break
    fi
    sleep 1
done

if [ "$READY" != "1" ]; then
    echo "✗ API did not become healthy"
    tail -40 "$RUNTIME/next.log"
    exit 1
fi

echo "✓ API healthy"

echo "[7] ACCEPT ROUTE MOUNT CHECK"

CODE="$(
curl -sS \
    -o "$RUNTIME/step11-route-check.out" \
    -w "%{http_code}" \
    -X POST \
    http://127.0.0.1:3000/api/requests/DOES_NOT_EXIST/accept
)"

echo "HTTP=$CODE"

if [ "$CODE" = "500" ]; then
    echo "✗ Runtime/import failure remains"
    tail -50 "$RUNTIME/next.log"
    exit 1
fi

if [ "$CODE" != "404" ]; then
    echo "✓ Route mounted and responded: HTTP $CODE"
else
    echo "✓ Route mounted; nonexistent request correctly returned 404"
fi

echo "[8] CREATE TEST CUSTOMER"

C="$(
curl -fsS -X POST \
    http://127.0.0.1:3000/api/customers \
    -H 'Content-Type: application/json' \
    -d '{"name":"STEP11 ACCEPT TEST","phone":"0000000011"}' |
node -e '
let s="";
process.stdin.on("data",d=>s+=d);
process.stdin.on("end",()=>{
    const j=JSON.parse(s);
    process.stdout.write((j.data||{}).id||"");
});
'
)"

test -n "$C"
echo "✓ Customer: $C"

echo "[9] CREATE TEST REQUEST"

R="$(
curl -fsS -X POST \
    http://127.0.0.1:3000/api/requests \
    -H 'Content-Type: application/json' \
    -d "{\"customerId\":\"$C\",\"pickup\":\"STEP11\",\"destination\":\"STEP11\"}" |
node -e '
let s="";
process.stdin.on("data",d=>s+=d);
process.stdin.on("end",()=>{
    const j=JSON.parse(s);
    process.stdout.write((j.data||{}).id||"");
});
'
)"

test -n "$R"
echo "✓ Request: $R"

echo "[10] ACCEPT REQUEST"

HTTP="$(
curl -sS \
    -o "$RUNTIME/step11-accept.json" \
    -w "%{http_code}" \
    -X POST \
    "http://127.0.0.1:3000/api/requests/$R/accept"
)"

echo "HTTP=$HTTP"

if [ "$HTTP" != "201" ] && [ "$HTTP" != "200" ]; then
    echo "✗ Accept failed"
    cat "$RUNTIME/step11-accept.json"
    echo
    tail -50 "$RUNTIME/next.log"
    exit 1
fi

O="$(
cat "$RUNTIME/step11-accept.json" |
node -e '
let s="";
process.stdin.on("data",d=>s+=d);
process.stdin.on("end",()=>{
    const j=JSON.parse(s);
    process.stdout.write((j.order||{}).id||"");
});
'
)"

test -n "$O"

echo "✓ ACCEPT PASSED"
echo "✓ Order: $O"

echo "[11] VERIFY REQUEST"

curl -fsS \
    "http://127.0.0.1:3000/api/requests/$R" \
    > "$RUNTIME/step11-request.json"

echo "✓ Request retrievable"

echo "[12] VERIFY ORDER"

curl -fsS \
    "http://127.0.0.1:3000/api/orders/$O" \
    > "$RUNTIME/step11-order.json"

echo "✓ Order retrievable"

echo "[13] CHECKPOINT"

printf '11\n' > .runner-state

echo
echo "=== REQUEST RUNNER® ==="
echo
echo "✓ STEP 11 IMPORTS REPAIRED"
echo "✓ ACCEPT ROUTE MOUNTED"
echo "✓ ACCEPT ENDPOINT PASSED"
echo "✓ ORDER CREATED"
echo "✓ REQUEST RETRIEVABLE"
echo "✓ ORDER RETRIEVABLE"
echo
echo "CHECKPOINT: 11"
echo "STEP 11 STATUS: PASS"
