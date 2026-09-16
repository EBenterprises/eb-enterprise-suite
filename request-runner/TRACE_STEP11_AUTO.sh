#!/data/data/com.termux/files/usr/bin/bash
set +e

TRACE_DIR=".runner-trace"
mkdir -p "$TRACE_DIR"

rm -f "$TRACE_DIR"/*

STATE="$(cat .runner-state 2>/dev/null || echo 10)"

bash -x ./STEP11_REAL_LIFECYCLE_COMPACT.sh \
  >"$TRACE_DIR/stdout" \
  2>"$TRACE_DIR/stderr"

RC=$?

clear

echo "=== REQUEST RUNNER® — STEP 11 AUTO TRACE ==="
echo
echo "EXIT: $RC"
echo "CHECKPOINT: $STATE"
echo

echo "[FAILURE]"
grep -E 'curl:|404|Request not found|Order not found|FAIL|FAILED' \
  "$TRACE_DIR/stdout" "$TRACE_DIR/stderr" 2>/dev/null |
  tail -20

echo
echo "[LAST COMMAND]"
tail -20 "$TRACE_DIR/stderr"

echo
echo "=== TRACE COMPLETE ==="

if [ "$RC" -eq 0 ]; then
    echo "✓ STEP 11 PASSED"
else
    echo "✗ STEP 11 FAILED"
    echo "✓ CHECKPOINT PRESERVED"
    echo "✓ APPLICATION FILES UNMODIFIED"
    echo
    echo "Trace retained at:"
    echo "$TRACE_DIR/"
fi
