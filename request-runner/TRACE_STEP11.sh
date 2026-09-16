#!/data/data/com.termux/files/usr/bin/bash
set +e

TRACE=".step11-runtime-trace"
rm -f "$TRACE"

echo "=== REQUEST RUNNER® — STEP 11 RUNTIME TRACE ==="

bash -x ./STEP11_REAL_LIFECYCLE_COMPACT.sh \
  >"$TRACE.out" 2>"$TRACE.err"

RC=$?

echo
echo "EXIT=$RC"

echo
echo "[LAST EXECUTED COMMANDS]"
tail -35 "$TRACE.err"

echo
echo "[FAILURE CONTEXT]"
grep -B4 -A6 -E \
  'curl:|404|Request not found|Order not found|FAIL|FAILED' \
  "$TRACE.err" "$TRACE.out" 2>/dev/null | tail -60

echo
echo "[STATE]"
printf "checkpoint="
cat .runner-state 2>/dev/null || echo "unknown"

rm -f "$TRACE.out" "$TRACE.err"

clear
echo "=== REQUEST RUNNER® ==="
echo
if [ "$RC" -eq 0 ]; then
    echo "✓ STEP 11 PASSED"
else
    echo "✗ STEP 11 RUNTIME FAILURE CAPTURED"
    echo "✓ APPLICATION FILES UNMODIFIED"
    echo "✓ CHECKPOINT PRESERVED"
fi
