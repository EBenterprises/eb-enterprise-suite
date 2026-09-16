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
