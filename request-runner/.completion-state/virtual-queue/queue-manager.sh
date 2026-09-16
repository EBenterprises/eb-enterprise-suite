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
