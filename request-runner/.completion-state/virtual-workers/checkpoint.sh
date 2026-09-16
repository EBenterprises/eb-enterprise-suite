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
