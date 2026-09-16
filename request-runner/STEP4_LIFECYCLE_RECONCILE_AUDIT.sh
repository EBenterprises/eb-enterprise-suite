#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=============================================================="
echo " EB PLATFORM® — STEP 4 LIFECYCLE RECONCILIATION AUDIT"
echo "=============================================================="

echo
echo "=== SERVER ENTRYPOINT ==="
sed -n '1,220p' server.js 2>/dev/null || true

echo
echo "=== PACKAGE / START COMMANDS ==="
node -e '
const p=require("./package.json");
console.log(JSON.stringify({
  name:p.name,
  scripts:p.scripts,
  dependencies:p.dependencies
},null,2))
' 2>/dev/null || true

echo
echo "=== FRAMEWORK APPLICATION ==="
sed -n '1,220p' framework/application.js 2>/dev/null || true

echo
echo "=== CRUD ROUTE IMPLEMENTATION ==="
sed -n '1,260p' framework/api/crud-route.js 2>/dev/null || true

echo
echo "=== PERSISTENCE IMPLEMENTATION ==="
find framework/data api -maxdepth 3 -type f \
  \( -name '*.js' -o -name '*.json' \) \
  -print 2>/dev/null | sort

echo
echo "=== SOCKET.IO REFERENCES ==="
grep -RInE \
'order:create|order:update|orders:snapshot|order:created|order:updated|socket\.io|Socket\.io' \
. \
--exclude-dir=node_modules \
--exclude-dir=.next \
--exclude-dir=.git \
--exclude='STEP*.sh' \
2>/dev/null | head -500 || true

echo
echo "=== API LIFECYCLE REFERENCES ==="
grep -RInE \
'/accept|/status|/assign|createOrderFromRequest|updateOrderStatus|updateRequestStatus' \
app api framework \
--exclude-dir=node_modules \
--exclude-dir=.next \
--exclude-dir=.git \
2>/dev/null | head -500 || true

echo
echo "=== DOMAIN MODELS ==="
for f in framework/domain/request.js framework/domain/order.js; do
    if [ -f "$f" ]; then
        echo "--- $f"
        cat "$f"
    fi
done

echo
echo "=== ACTIVE PROCESSES ==="
ps -ef 2>/dev/null | grep -E 'node|next|request-runner' | grep -v grep || true

echo
echo "=== PORT CHECK ==="
for port in 3000 3001 8080 8081; do
    if command -v curl >/dev/null 2>&1; then
        if curl -s --max-time 1 "http://127.0.0.1:$port/api/health" >/dev/null 2>&1; then
            echo "PORT $port: HTTP HEALTH RESPONDS"
        else
            echo "PORT $port: no HTTP health response"
        fi
    fi
done

echo
echo "=============================================================="
echo " STEP 4 AUDIT COMPLETE — NO DATA MODIFIED"
echo "=============================================================="
