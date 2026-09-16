#!/data/data/com.termux/files/usr/bin/bash
set +e

clear
echo "=== REQUEST RUNNER® — API MOUNT AUDIT ==="
echo

echo "[LISTENING PORTS]"
if command -v ss >/dev/null 2>&1; then
    ss -ltnp 2>/dev/null | grep -E ':(3000|3001|3002|4000|4001|8080|8081)' || true
else
    netstat -ltn 2>/dev/null | grep -E ':(3000|3001|3002|4000|4001|8080|8081)' || true
fi

echo
echo "[RUNNING NODE]"
ps -ef 2>/dev/null | grep '[n]ode' || true

echo
echo "[SERVER/API MOUNTS]"
grep -RniE \
  'platform-api|createPlatform|/api|listen\(' \
  --exclude-dir=node_modules \
  --exclude-dir=.next \
  --exclude='*.map' \
  . 2>/dev/null | head -120

echo
echo "[PACKAGE SCRIPTS]"
node -e '
const fs=require("fs");
const p=JSON.parse(fs.readFileSync("package.json","utf8"));
console.log(JSON.stringify(p.scripts||{},null,2));
'

echo
echo "[CHECKPOINT]"
printf "checkpoint="
cat .runner-state 2>/dev/null || echo "unknown"

echo
echo "=== AUDIT COMPLETE ==="
