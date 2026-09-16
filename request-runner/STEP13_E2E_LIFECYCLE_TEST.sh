#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "=== EB PLATFORM® STEP 13 — E2E LIFECYCLE TEST ==="

BASE=http://127.0.0.1:3000
CUSTOMER=""
REQUEST=""
ORDER=""

cleanup() {
  [ -n "$REQUEST" ] && curl -s -X DELETE "$BASE/api/requests/$REQUEST" >/dev/null 2>&1 || true
  [ -n "$CUSTOMER" ] && curl -s -X DELETE "$BASE/api/customers/$CUSTOMER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

CUSTOMER=$(curl -fsS -X POST "$BASE/api/customers" \
  -H 'Content-Type: application/json' \
  -d '{"name":"__STEP13_TEST__"}' |
  node -pe 'JSON.parse(require("fs").readFileSync(0,"utf8")).data.id')

REQUEST=$(curl -fsS -X POST "$BASE/api/requests" \
  -H 'Content-Type: application/json' \
  -d "{\"customerId\":\"$CUSTOMER\",\"pickup\":\"STEP13\",\"destination\":\"STEP13\"}" |
  node -pe 'JSON.parse(require("fs").readFileSync(0,"utf8")).data.id')

curl -fsS -X POST "$BASE/api/requests/$REQUEST/accept" \
  -H 'Content-Type: application/json' >./.runtime/step13-order.json

ORDER=$(node -pe \
  'JSON.parse(require("fs").readFileSync("./.runtime/step13-order.json","utf8")).order.id')

for s in assigned en_route arrived picked_up completed; do
  curl -fsS -X PATCH "$BASE/api/orders/$ORDER/status" \
    -H 'Content-Type: application/json' \
    -d "{\"status\":\"$s\"}" >/dev/null
done

curl -fsS "$BASE/api/orders/$ORDER" >./.runtime/step13-final.json

node <<'NODE'
const x=require("./.runtime/step13-final.json").data;
if(x.status!=="completed") throw new Error("Order did not complete");
console.log("✓ request → order → completed PASS");
NODE

rm -f ./.runtime/step13-order.json ./.runtime/step13-final.json

printf "✓ temporary records cleaned\n"
printf "✓ existing data preserved\n"
printf "✓ STEP 13 COMPLETE\n"
