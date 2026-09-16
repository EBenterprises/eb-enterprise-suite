#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STATE="$ROOT/.runner-state"
LOG="$ROOT/.runner.log"

LAST=0
[ -f "$STATE" ] && LAST="$(cat "$STATE")"

clear

echo "=== REQUEST RUNNER® ==="
echo "RESUME FROM STEP: $LAST"
echo

for step in $(find "$ROOT" -maxdepth 1 -type f -name 'STEP*.sh' -printf '%f\n' 2>/dev/null | sort -V); do

    num="$(printf '%s\n' "$step" | sed -n 's/^STEP\([0-9][0-9]*\).*/\1/p')"

    [ -n "$num" ] || continue
    [ "$num" -gt "$LAST" ] || continue

    clear
    echo "=== REQUEST RUNNER® ==="
    echo "RUN: $step"
    echo

    chmod 700 "$step"

    if "./$step" >"$LOG" 2>&1; then
        echo "$num" > "$STATE"
        rm -f "$LOG"

        echo "✓ PASS: $step"
        sleep 0.2
    else
        clear
        echo "=== REQUEST RUNNER® FAILURE ==="
        echo
        echo "STEP: $step"
        echo "NUMBER: $num"
        echo
        tail -50 "$LOG" 2>/dev/null || true
        echo
        echo "STATE REMAINS: $LAST"
        exit 1
    fi
done

rm -f "$LOG"

clear
echo "=== REQUEST RUNNER® ==="
echo
echo "✓ ALL REMAINING STEPS PASSED"
echo "✓ CHECKPOINT: $(cat "$STATE" 2>/dev/null || echo "$LAST")"
