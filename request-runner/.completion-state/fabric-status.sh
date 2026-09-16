#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

RAM="$(awk '/MemAvailable/ {printf "%d",$2/1024; exit}' /proc/meminfo)"
DISK="$(df -Pm "$ROOT" | awk 'NR==2 {print $4}')"

HOT="$(find "$ROOT/virtual-workers/hot" \
    -mindepth 1 -maxdepth 1 \
    -type d 2>/dev/null | wc -l)"

WARM="$(find "$ROOT/virtual-workers/warm" \
    -mindepth 1 -maxdepth 1 \
    -type d 2>/dev/null | wc -l)"

COLD="$(find "$ROOT/virtual-workers/cold" \
    -mindepth 1 -maxdepth 1 \
    -type d 2>/dev/null | wc -l)"

QUEUE="$(find "$ROOT/virtual-queue" \
    -type f \
    -name '*.json' 2>/dev/null | wc -l)"

echo "=============================================================="
echo " VIRTUAL RESOURCE FABRIC® STATUS"
echo "=============================================================="
echo "RAM available : ${RAM} MB"
echo "Disk free     : ${DISK} MB"
echo "Hot workers   : $HOT"
echo "Warm workers  : $WARM"
echo "Cold workers  : $COLD"
echo "Queued tasks  : $QUEUE"
echo "=============================================================="
