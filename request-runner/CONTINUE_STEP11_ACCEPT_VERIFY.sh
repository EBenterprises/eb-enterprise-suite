#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/request-runner"
cd "$ROOT"

RUNTIME="$ROOT/.runtime"
mkdir -p "$RUNTIME"

CODE_FILE="$RUNTIME/step11-route-code"
ROUTE_OUT="$RUNTIME/step11-route-check.out"
ACCEPT_OUT="$RUNTIME/step11-accept.json"
REQUEST_OUT="$RUNTIME/step11-request.json"
ORDER_OUT="$RUNTIME/step11-order.json"

echo "=== REQUEST RUNNER® — STEP 11 ACCEPT VERIFY ==="
echo

echo "[1] ROUTE FILE"
test -f 'app/api/requests/[id]/accept/route.js'
echo "✓ Accept route exists"

echo "[2] SYNTAX"
node --check 'app/api/requests/[id]/accept/route.js'
node --check api/domain-service.js
node --check api/store.js
echo "✓ Syntax valid"

echo "[3] ROUTE CONTENT"
grep -n "async function POST" 'app/api/requests/[id]/accept/route.js'
grep -n "createOrderFromRequest" 'app/api/requests/[id]/accept/route.js'
echo "✓ Route implementation confirmed"

echo "[4] ACTIVE NEXT PROCESS"
ps -ef 2>/dev/null | grep '[n]ext' || true
echo

echo "[5] HEALTH"
curl -fsS http://127.0.0.1:3000/api/health >/dev/null
echo "✓ API healthy"

echo "[6] ACCEPT ROUTE MOUNT CHECK"

rm -f "$CODE_FILE" "$ROUTE_OUT"

curl -sS \
  -o "$ROUTE_OUT" \
  -w "%{http_code}" \
  -X POST \
  http://127.0.0.1:3000/api/requests/DOES_NOT_EXIST/accept \
  > "$CODE_FILE"

CODE="$(cat "$CODE_FILE")"

echo "HTTP=$CODE"

if [ "$CODE" = "404" ]; then
    echo
    echo "✗ ACCEPT ROUTE STILL RETURNS 404"
    echo
    echo "--- RESPONSE ---"
    cat "$ROUTE_OUT"
    echo
    echo "--- NEXT LOG TAIL ---"
    tail -80 "$RUNTIME/next.log" || true
    exit 1
fi

if [ "$CODE" = "500" ]; then
    echo
    echo "✗ ACCEPT ROUTE MOUNTED BUT HAS RUNTIME ERROR"
    echo
    cat "$ROUTE_OUT"
    echo
    tail -80 "$RUNTIME/next.log" || true
    exit 1
fi

echo "✓ Accept endpoint is mounted"
echo

echo "[7] CREATE TEST CUSTOMER"

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

echo "[8] CREATE TEST REQUEST"

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

echo "[9] ACCEPT REQUEST"

curl -fsS -X POST \
  "http://127.0.0.1:3000/api/requests/$R/accept" \
  > "$ACCEPT_OUT"

echo "✓ Accept response received"

O="$(
cat "$ACCEPT_OUT" |
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

echo "[10] VERIFY REQUEST"

curl -fsS \
  "http://127.0.0.1:3000/api/requests/$R" \
  > "$REQUEST_OUT"

node - "$REQUEST_OUT" <<'NODE'
const fs = require("fs");
const file = process.argv[2];
const j = JSON.parse(fs.readFileSync(file, "utf8"));
const d = j.data || j;
if (!d.id) process.exit(1);
console.log("✓ Request retrievable");
console.log("  id=" + d.id);
console.log("  status=" + (d.status || "unknown"));
NODE

echo "[11] VERIFY ORDER"

curl -fsS \
  "http://127.0.0.1:3000/api/orders/$O" \
  > "$ORDER_OUT"

node - "$ORDER_OUT" <<'NODE'
const fs = require("fs");
const file = process.argv[2];
const j = JSON.parse(fs.readFileSync(file, "utf8"));
const d = j.data || j;
if (!d.id) process.exit(1);
console.log("✓ Order retrievable");
console.log("  id=" + d.id);
console.log("  status=" + (d.status || "unknown"));
NODE

echo "[12] ACCEPT RESPONSE"
cat "$ACCEPT_OUT"

echo
echo "[13] CHECKPOINT"

printf '11\n' > .runner-state

echo
echo "=== REQUEST RUNNER® ==="
echo
echo "✓ STEP 11 ACCEPT ROUTE REPAIRED"
echo "✓ APP ROUTER ROUTE MOUNTED"
echo "✓ ACCEPT ENDPOINT RESPONDS"
echo "✓ ORDER CREATED"
echo "✓ REQUEST RETRIEVABLE"
echo "✓ ORDER RETRIEVABLE"
echo
echo "CHECKPOINT: 11"
echo
echo "STEP 11 STATUS: PASS"
