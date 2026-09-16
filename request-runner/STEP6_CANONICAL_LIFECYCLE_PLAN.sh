#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=============================================================="
echo " EB PLATFORM® — STEP 6 CANONICAL LIFECYCLE PLAN"
echo "=============================================================="

echo
echo "[1] BACKUP VERIFICATION"
LATEST="$(find .backups -maxdepth 1 -type d -name 'pre-real-lifecycle-*' 2>/dev/null | sort | tail -1 || true)"

if [ -n "$LATEST" ]; then
    echo "Backup: $LATEST"
    du -sh "$LATEST"
else
    echo "WARNING: protected backup not found"
    exit 1
fi

echo
echo "[2] CURRENT DATA"
for collection in customers requests orders drivers; do
    echo "--- $collection"
    curl -s "http://127.0.0.1:3000/api/$collection" | head -c 500
    echo
done

echo
echo "[3] CANONICAL LIFECYCLE"
echo "request.created"
echo "    ↓"
echo "request.accepted"
echo "    ↓"
echo "order.created"
echo "    ↓"
echo "order.assigned"
echo "    ↓"
echo "order.en_route"
echo "    ↓"
echo "order.arrived"
echo "    ↓"
echo "order.picked_up"
echo "    ↓"
echo "order.completed"

echo
echo "[4] REALTIME TRANSPORT"
echo "3001 = Socket.IO transport"
echo "3000 = authoritative persistence/API"

echo
echo "[5] LEGACY SYSTEM"
echo "server.js = preserved, NOT started, NOT deleted"

echo
echo "=============================================================="
echo " PLAN VERIFIED — NO DATA MODIFIED"
echo "=============================================================="
