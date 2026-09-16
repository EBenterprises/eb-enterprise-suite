#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEP 5 RUNTIME MAP ==="

echo
echo "[PROCESSES]"
ps -ef | grep -E 'realtime-server|npm run dev|next dev' | grep -v grep || true

echo
echo "[3000 HEALTH]"
curl -s http://127.0.0.1:3000/api/health || true
echo

echo
echo "[3001 HEALTH]"
curl -s http://127.0.0.1:3001/api/health || true
echo

echo
echo "[3001 ROOT]"
curl -s -I --max-time 2 http://127.0.0.1:3001/ 2>/dev/null | head -10 || true

echo
echo "[REALTIME SERVER]"
sed -n '1,180p' realtime-server.js 2>/dev/null || echo "realtime-server.js not found"

echo
echo "[START CONFIG]"
grep -RInE \
'3000|3001|realtime-server|PORT=' \
package.json \
*.js \
scripts \
--exclude-dir=node_modules \
--exclude-dir=.next \
2>/dev/null | head -100 || true

echo
echo "=== STEP 5 COMPLETE — NO DATA MODIFIED ==="
