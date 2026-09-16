#!/data/data/com.termux/files/usr/bin/bash
set -e

PASS(){ echo "✓ $1"; }
FAIL(){ echo "✗ $1"; exit 1; }

echo "=== EB PLATFORM® STEP 11 — COMPACT E2E ==="

BACKUP=".backups/pre-real-lifecycle-20260810-143832"
test -d "$BACKUP" && PASS "Backup verified" || FAIL "Backup missing"

node --check api/domain-service.js >/dev/null
node --check framework/lifecycle/canonical-lifecycle.js >/dev/null
PASS "Syntax"

curl -fsS http://127.0.0.1:3000/api/health >/dev/null
PASS "API healthy"

node <<'NODE'
const l=require("./framework/lifecycle/canonical-lifecycle");
[
 ["pending","accepted"],
 ["accepted","assigned"],
 ["assigned","en_route"],
 ["en_route","arrived"],
 ["arrived","picked_up"],
 ["picked_up","completed"]
].forEach(x=>l.assertRequestTransition(...x));
[
 ["pending","confirmed"],
 ["confirmed","assigned"],
 ["assigned","en_route"],
 ["en_route","arrived"],
 ["arrived","picked_up"],
 ["picked_up","completed"]
].forEach(x=>l.assertOrderTransition(...x));
NODE
PASS "Canonical transitions"

C=$(
curl -fsS -X POST http://127.0.0.1:3000/api/customers \
-H 'Content-Type: application/json' \
-d '{"name":"STEP11 TEST","phone":"0000000011"}' |
node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>process.stdout.write((JSON.parse(s).data||{}).id||""))'
)

test -n "$C" && PASS "Test customer created" || FAIL "Customer creation"

R=$(
curl -fsS -X POST http://127.0.0.1:3000/api/requests \
-H 'Content-Type: application/json' \
-d "{\"customerId\":\"$C\",\"pickup\":\"STEP11\",\"destination\":\"STEP11\"}" |
node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>process.stdout.write((JSON.parse(s).data||{}).id||""))'
)

test -n "$R" && PASS "Test request created" || FAIL "Request creation"

A=$(
curl -fsS -X POST \
"http://127.0.0.1:3000/api/requests/$R/accept"
)

O=$(
printf '%s' "$A" |
node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>process.stdout.write((JSON.parse(s).order||{}).id||""))'
)

test -n "$O" && PASS "Accept → order created" || FAIL "Order creation"

D=$(
curl -fsS -X POST http://127.0.0.1:3000/api/drivers \
-H 'Content-Type: application/json' \
-d '{"name":"STEP11 TEST DRIVER"}' |
node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>process.stdout.write((JSON.parse(s).data||{}).id||""))'
)

test -n "$D" && PASS "Test driver created" || FAIL "Driver creation"

curl -fsS -X POST \
"http://127.0.0.1:3000/api/requests/$R/assign" \
-H 'Content-Type: application/json' \
-d "{\"driverId\":\"$D\"}" >/dev/null
PASS "Accepted → assigned"

for S in en_route arrived picked_up completed; do
    curl -fsS -X PATCH \
    "http://127.0.0.1:3000/api/requests/$R/status" \
    -H 'Content-Type: application/json' \
    -d "{\"status\":\"$S\"}" >/dev/null

    curl -fsS -X PATCH \
    "http://127.0.0.1:3000/api/orders/$O/status" \
    -H 'Content-Type: application/json' \
    -d "{\"status\":\"$S\"}" >/dev/null

    PASS "→ $S"
done

REQ_STATUS=$(
curl -fsS "http://127.0.0.1:3000/api/requests/$R" |
node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>process.stdout.write((JSON.parse(s).data||{}).status||""))'
)

ORD_STATUS=$(
curl -fsS "http://127.0.0.1:3000/api/orders/$O" |
node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>process.stdout.write((JSON.parse(s).data||{}).status||""))'
)

[ "$REQ_STATUS" = "completed" ] && PASS "Request final = completed" || FAIL "Request final state"
[ "$ORD_STATUS" = "completed" ] && PASS "Order final = completed" || FAIL "Order final state"

CODE=$(
curl -s -o /dev/null -w "%{http_code}" \
-X PATCH "http://127.0.0.1:3000/api/orders/$O/status" \
-H 'Content-Type: application/json' \
-d '{"status":"pending"}'
)

[ "$CODE" = "400" ] && PASS "Terminal protection" || FAIL "Terminal protection"

echo
echo "=== STEP 11 PASS ==="
echo "Customer: $C"
echo "Request:  $R"
echo "Order:    $O"
echo "Driver:   $D"
echo
echo "Lifecycle: pending → accepted → assigned → en_route → arrived → picked_up → completed"
echo "Next: STEP 12 — realtime + Ops UI reconciliation"
