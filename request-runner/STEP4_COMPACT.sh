#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEP 4 COMPACT ==="

echo
echo "[1] PACKAGE"
node -e 'const p=require("./package.json"); console.log("name:",p.name); console.log("scripts:",JSON.stringify(p.scripts))' 2>/dev/null || true

echo
echo "[2] ENTRYPOINT"
grep -nE 'listen|socket|io\.on|order:create|order:update|express|next' server.js 2>/dev/null | head -80 || true

echo
echo "[3] LIFECYCLE"
grep -RInE 'createOrderFromRequest|/accept|/status|/assign|order:create|order:update' \
app api framework \
--exclude-dir=node_modules \
--exclude-dir=.next \
--exclude-dir=.git \
2>/dev/null | head -120 || true

echo
echo "[4] PROCESSES"
ps -ef 2>/dev/null | grep -E 'node|next' | grep -v grep || echo "No Node/Next process"

echo
echo "[5] PORTS"
for p in 3000 3001 8080 8081; do
  if curl -s --max-time 1 "http://127.0.0.1:$p/api/health" >/dev/null 2>&1; then
    echo "$p = ACTIVE"
  else
    echo "$p = inactive"
  fi
done

echo
echo "[6] DATA COUNTS"
for x in customers requests orders drivers; do
  curl -s --max-time 2 "http://127.0.0.1:3000/api/$x" 2>/dev/null |
    node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{let x=JSON.parse(s); console.log(x.count ?? x.data?.length ?? 0)}catch{console.log("ERR")}})' |
    sed "s/^/$x: /"
done

echo
echo "=== STEP 4 COMPLETE — NO DATA MODIFIED ==="
