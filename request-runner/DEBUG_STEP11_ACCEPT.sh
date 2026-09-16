#!/data/data/com.termux/files/usr/bin/bash
set +e

clear
echo "=== REQUEST RUNNER® — ACCEPT PATH DEBUG ==="
echo

C=$(curl -fsS -X POST \
  http://127.0.0.1:3000/api/customers \
  -H 'Content-Type: application/json' \
  -d '{"name":"STEP11 DEBUG","phone":"0000000011"}' |
  node -e '
    let s="";
    process.stdin.on("data",d=>s+=d);
    process.stdin.on("end",()=>console.log((JSON.parse(s).data||{}).id||""));
  ')

R=$(curl -fsS -X POST \
  http://127.0.0.1:3000/api/requests \
  -H 'Content-Type: application/json' \
  -d "{\"customerId\":\"$C\",\"pickup\":\"STEP11\",\"destination\":\"STEP11\"}" |
  node -e '
    let s="";
    process.stdin.on("data",d=>s+=d);
    process.stdin.on("end",()=>console.log((JSON.parse(s).data||{}).id||""));
  ')

echo "CUSTOMER=$C"
echo "REQUEST=$R"
echo

echo "[ACCEPT RESPONSE]"
curl -sS -i -X POST \
  "http://127.0.0.1:3000/api/requests/$R/accept"

echo
echo
echo "[REQUEST STILL EXISTS]"
curl -sS \
  "http://127.0.0.1:3000/api/requests/$R"

echo
echo
echo "=== DEBUG COMPLETE ==="
