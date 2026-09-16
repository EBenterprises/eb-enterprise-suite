#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

ENGINE="VIRTUAL_RESOURCE_FABRIC® V1"

STATE=".completion-state"
VRAM="$STATE/virtual-memory"
POOL="$STATE/virtual-workers"
QUEUE="$STATE/virtual-queue"
LOGDIR=".completion-logs"

mkdir -p "$VRAM" "$POOL" "$QUEUE" "$LOGDIR"

TS="$(date +%Y%m%d-%H%M%S)"
LOG="$LOGDIR/virtual-fabric-$TS.log"

exec > >(tee "$LOG") 2>&1

echo "=============================================================="
echo " $ENGINE"
echo "=============================================================="
echo "Run: $TS"
echo

CPU="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"
RAM_MB="$(awk '/MemAvailable/ {printf "%d",$2/1024; exit}' /proc/meminfo 2>/dev/null || echo 0)"
DISK_MB="$(df -Pm . | awk 'NR==2 {print $4}')"

echo "[PHYSICAL RESOURCE DISCOVERY]"
echo "CPU cores       : $CPU"
echo "RAM available   : ${RAM_MB} MB"
echo "Disk available  : ${DISK_MB} MB"
echo

#
# --------------------------------------------------------------
# VIRTUAL MEMORY POLICY
# --------------------------------------------------------------
#

# Never consume the entire device.
#
# Reserve at most 50% of currently free storage for the virtual
# resource fabric.
#
# Minimum 512 MB.
# Maximum 16 GB unless explicitly expanded later.
#

if [ "$DISK_MB" -gt 32768 ]; then
    VIRTUAL_MB=$((DISK_MB / 2))
    [ "$VIRTUAL_MB" -gt 16384 ] && VIRTUAL_MB=16384
elif [ "$DISK_MB" -gt 2048 ]; then
    VIRTUAL_MB=$((DISK_MB / 2))
else
    VIRTUAL_MB=512
fi

echo "Virtual capacity target: ${VIRTUAL_MB} MB"

#
# Sparse virtual-memory backing file.
#
# Sparse files consume blocks as actually written rather than
# immediately allocating their logical size.
#

VFILE="$VRAM/fabric-${VIRTUAL_MB}MB.img"

if [ ! -f "$VFILE" ]; then
    echo "Creating sparse virtual memory backing store..."

    truncate -s "${VIRTUAL_MB}M" "$VFILE" 2>/dev/null || {
        echo "truncate unavailable; creating logical storage file"
        dd if=/dev/zero \
           of="$VFILE" \
           bs=1M \
           count=1 \
           seek=$((VIRTUAL_MB-1)) \
           status=none
    }
fi

ACTUAL_MB="$(du -m "$VFILE" 2>/dev/null | awk '{print $1}')"

echo "Logical virtual memory: ${VIRTUAL_MB} MB"
echo "Physical storage used : ${ACTUAL_MB:-0} MB"

#
# --------------------------------------------------------------
# WORKER SPACE
# --------------------------------------------------------------
#

mkdir -p \
    "$POOL/hot" \
    "$POOL/warm" \
    "$POOL/cold" \
    "$POOL/checkpoints" \
    "$POOL/artifacts"

#
# Hot workers stay in RAM.
# Warm workers retain working state on filesystem.
# Cold workers become serialized state.
#

if [ "$RAM_MB" -lt 512 ]; then
    HOT_WORKERS=2
elif [ "$RAM_MB" -lt 1024 ]; then
    HOT_WORKERS=2
elif [ "$RAM_MB" -lt 2048 ]; then
    HOT_WORKERS=4
elif [ "$RAM_MB" -lt 4096 ]; then
    HOT_WORKERS=6
else
    HOT_WORKERS="$CPU"
fi

[ "$HOT_WORKERS" -gt 16 ] && HOT_WORKERS=16

echo
echo "[WORKER MEMORY POLICY]"
echo "Hot workers : $HOT_WORKERS"
echo "Warm space  : filesystem-backed"
echo "Cold space  : serialized"
echo "Virtual pool : expandable"

#
# --------------------------------------------------------------
# VIRTUAL WORKER IDENTITIES
# --------------------------------------------------------------
#

cat > "$POOL/policy.json" <<JSON
{
  "engine": "$ENGINE",
  "physical_ram_mb": $RAM_MB,
  "physical_cpu": $CPU,
  "disk_available_mb": $DISK_MB,
  "virtual_capacity_mb": $VIRTUAL_MB,
  "hot_workers": $HOT_WORKERS,
  "warm_workers": "unbounded_by_design",
  "cold_workers": "unbounded_by_storage",
  "strategy": "hot-warm-cold",
  "ram_policy": "adaptive",
  "storage_policy": "sparse",
  "worker_policy": "queue-backed"
}
JSON

#
# --------------------------------------------------------------
# INFINITE LOGICAL WORKER SPACE
# --------------------------------------------------------------
#

cat > "$POOL/spawn-worker.sh" <<'WORKER'
#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
POOL="$ROOT/.completion-state/virtual-workers"

NAME="${1:-worker}"
TASK="${2:-idle}"

ID="$(date +%s%N)-$$"
DIR="$POOL/cold/$ID"

mkdir -p "$DIR"

cat > "$DIR/state.json" <<JSON
{
  "id": "$ID",
  "name": "$NAME",
  "task": "$TASK",
  "status": "QUEUED",
  "created": "$(date -Iseconds)",
  "storage_backed": true
}
JSON

echo "$ID"
WORKER

chmod +x "$POOL/spawn-worker.sh"

#
# --------------------------------------------------------------
# WORK QUEUE
# --------------------------------------------------------------
#

cat > "$QUEUE/queue-manager.sh" <<'QUEUE'
#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
POOL="$ROOT/.completion-state/virtual-workers"
QUEUE="$ROOT/.completion-state/virtual-queue"

mkdir -p "$QUEUE"

enqueue() {
    local task="$1"
    local id

    id="$(date +%s%N)-$$"

    cat > "$QUEUE/$id.json" <<JSON
{
  "id": "$id",
  "task": "$task",
  "status": "QUEUED",
  "created": "$(date -Iseconds)"
}
JSON

    echo "$id"
}

dequeue() {
    local f

    f="$(find "$QUEUE" \
        -maxdepth 1 \
        -type f \
        -name '*.json' \
        | sort \
        | head -1)"

    [ -n "$f" ] || return 1

    echo "$f"
}

case "${1:-}" in
    enqueue)
        enqueue "${2:-unspecified}"
        ;;

    dequeue)
        dequeue
        ;;

    *)
        echo "usage: queue-manager.sh enqueue TASK"
        echo "       queue-manager.sh dequeue"
        exit 1
        ;;
esac
QUEUE

chmod +x "$QUEUE/queue-manager.sh"

#
# --------------------------------------------------------------
# RESOURCE GOVERNOR
# --------------------------------------------------------------
#

cat > "$STATE/resource-governor.sh" <<'GOV'
#!/data/data/com.termux/files/usr/bin/bash
set -u

RAM_MB="$(awk '/MemAvailable/ {printf "%d",$2/1024; exit}' /proc/meminfo 2>/dev/null || echo 0)"

if [ "$RAM_MB" -lt 256 ]; then
    echo "CRITICAL"
    exit 3
elif [ "$RAM_MB" -lt 512 ]; then
    echo "LOW"
    exit 2
elif [ "$RAM_MB" -lt 1024 ]; then
    echo "CONSTRAINED"
    exit 1
else
    echo "HEALTHY"
    exit 0
fi
GOV

chmod +x "$STATE/resource-governor.sh"

#
# --------------------------------------------------------------
# SNAPSHOT / SPILL SYSTEM
# --------------------------------------------------------------
#

cat > "$POOL/checkpoint.sh" <<'CHECKPOINT'
#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
POOL="$ROOT/.completion-state/virtual-workers"

ID="${1:-}"

[ -n "$ID" ] || {
    echo "worker id required"
    exit 1
}

SRC="$POOL/hot/$ID"
DST="$POOL/checkpoints/$ID"

[ -d "$SRC" ] || {
    echo "worker not found: $ID"
    exit 1
}

mkdir -p "$DST"

cp -a "$SRC/." "$DST/" 2>/dev/null || true

echo "CHECKPOINTED=$ID"
CHECKPOINT

chmod +x "$POOL/checkpoint.sh"

#
# --------------------------------------------------------------
# FABRIC STATUS
# --------------------------------------------------------------
#

cat > "$STATE/fabric-status.sh" <<'STATUS'
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
STATUS

chmod +x "$STATE/fabric-status.sh"

echo
echo "=============================================================="
echo " VIRTUAL RESOURCE FABRIC® — READY"
echo "=============================================================="
echo "Logical memory : ${VIRTUAL_MB} MB"
echo "Hot workers    : $HOT_WORKERS"
echo "Warm workers   : expandable"
echo "Cold workers   : storage-backed"
echo "Queue          : persistent"
echo "Check status   : $STATE/fabric-status.sh"
echo "Worker spawn   : $POOL/spawn-worker.sh"
echo "Queue manager  : $QUEUE/queue-manager.sh"
echo "=============================================================="

"$STATE/fabric-status.sh"
