#!/data/data/com.termux/files/usr/bin/bash

set -u

SECONDS_LIMIT="${1:-900}"
shift || true

if [ "$#" -eq 0 ]; then
    echo "RUN_WITH_TIMEOUT®: missing command"
    exit 2
fi

"$@" &
CHILD=$!

START="$(date +%s)"

while kill -0 "$CHILD" 2>/dev/null; do
    NOW="$(date +%s)"
    ELAPSED=$((NOW - START))

    if [ "$ELAPSED" -ge "$SECONDS_LIMIT" ]; then
        echo
        echo "TIMEOUT: command exceeded ${SECONDS_LIMIT}s"
        echo "PID: $CHILD"

        kill -TERM "$CHILD" 2>/dev/null || true
        sleep 3
        kill -KILL "$CHILD" 2>/dev/null || true

        wait "$CHILD" 2>/dev/null || true
        exit 124
    fi

    sleep 2
done

wait "$CHILD"
exit $?
