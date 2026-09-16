#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/request-runner"
cd "$ROOT"

BACKUP=".backups/step11-accept-route-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo "=== REQUEST RUNNER® — STEP 11 ACCEPT ROUTE REPAIR ==="

echo "[1] BACKUP"
if [ -f "app/api/requests/[id]/route.js" ]; then
  cp "app/api/requests/[id]/route.js" "$BACKUP/request-id-route.js"
fi
if [ -f "api/domain-service.js" ]; then
  cp "api/domain-service.js" "$BACKUP/domain-service.js"
fi
if [ -f "api/store.js" ]; then
  cp "api/store.js" "$BACKUP/store.js"
fi
echo "✓ Backup created"

echo "[2] VERIFY DOMAIN EXPORTS"
grep -nE 'createOrderFromRequest|module\.exports' api/domain-service.js | tail -20

echo "[3] CREATE MISSING APP ROUTE"

mkdir -p 'app/api/requests/[id]/accept'

cat > 'app/api/requests/[id]/accept/route.js' <<'ROUTE'
const domain = require("../../../../../../api/domain-service");
const store = require("../../../../../../api/store");

async function POST(request, context) {
    const params = await context.params;
    const id = params.id;

    const existing = store.findById("requests", id);

    if (!existing) {
        return Response.json(
            {
                ok: false,
                error: "Request not found",
                collection: "requests",
                id
            },
            { status: 404 }
        );
    }

    try {
        const order = domain.createOrderFromRequest(existing);

        const updated = store.findById("requests", id);

        return Response.json(
            {
                request: updated,
                order
            },
            { status: 201 }
        );
    } catch (error) {
        console.error("[REQUEST ACCEPT]", error);

        return Response.json(
            {
                ok: false,
                error: error.message || "Unable to accept request"
            },
            { status: 400 }
        );
    }
}

module.exports = { POST };
ROUTE

echo "✓ Accept route created"

echo "[4] SYNTAX"

node --check 'app/api/requests/[id]/accept/route.js'
node --check api/domain-service.js
node --check api/store.js

echo "✓ Syntax valid"

echo "[5] ROUTE CONFIRMATION"

test -f 'app/api/requests/[id]/accept/route.js'
grep -n "async function POST" 'app/api/requests/[id]/accept/route.js'
grep -n "createOrderFromRequest" 'app/api/requests/[id]/accept/route.js'

echo "✓ Route physically exists"

echo "[6] STOP OLD NEXT DEV"

pkill -f 'next-server' 2>/dev/null || true
pkill -f 'next dev --webpack' 2>/dev/null || true

sleep 2

echo "[7] START NEXT"

nohup npm run dev > .runtime/next.log 2>&1 &

NEXT_PID=$!
echo "$NEXT_PID" > .runtime/next.pid

sleep 5

echo "[8] HEALTH"

for i in 1 2 3 4 5 6 7 8 9 10; do
    if curl -fsS http://127.0.0.1:3000/api/health >/dev/null 2>&1; then
        echo "✓ API healthy"
        break
    fi
    sleep 1
done

curl -fsS http://127.0.0.1:3000/api/health >/dev/null

echo "[9] ROUTE COMPILE CHECK"

curl -sS -o /tmp/step11-route-check.out \
    -w "%{http_code}" \
    -X POST \
    http://127.0.0.1:3000/api/requests/DOES_NOT_EXIST/accept \
    > /tmp/step11-route-code

CODE=$(cat /tmp/step11-route-code)

echo "HTTP=$CODE"

if [ "$CODE" = "404" ]; then
    echo "✗ Route still resolving to Next not-found"
    tail -40 .runtime/next.log
    exit 1
fi

if [ "$CODE" = "500" ]; then
    echo "✗ Route compiled but has a runtime import/error"
    cat /tmp/step11-route-check.out
    tail -60 .runtime/next.log
    exit 1
fi

echo "✓ App Router accept endpoint is mounted"

echo "[10] STEP 11 REAL TEST"

C=$(
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
)

test -n "$C"
echo "✓ Customer: $C"

R=$(
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
)

test -n "$R"
echo "✓ Request: $R"

A=$(
curl -fsS -X POST \
"http://127.0.0.1:3000/api/requests/$R/accept"
)

echo "$A" > /tmp/step11-accept.json

O=$(
printf '%s' "$A" |
node -e '
let s="";
process.stdin.on("data",d=>s+=d);
process.stdin.on("end",()=>{
  const j=JSON.parse(s);
  process.stdout.write((j.order||{}).id||"");
});
'
)

test -n "$O"

echo "✓ ACCEPT PASSED"
echo "✓ Order: $O"

echo "[11] VERIFY REQUEST"

curl -fsS \
"http://127.0.0.1:3000/api/requests/$R" \
> /tmp/step11-request.json

echo "✓ Request retrievable"

echo "[12] VERIFY ORDER"

curl -fsS \
"http://127.0.0.1:3000/api/orders/$O" \
> /tmp/step11-order.json

echo "✓ Order retrievable"

echo "[13] CHECKPOINT"

printf '11\n' > .runner-state

clear

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
