#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG="$ROOT/.runner-step.log"

clear
cd "$ROOT"

rm -f "$LOG"

run_step() {
    local script="$1"

    [ "$script" = "RUNNER_COMPILE.sh" ] && return 0

    chmod 700 "$script"

    clear
    echo "=== REQUEST RUNNER® ==="
    echo "RUN: $script"
    echo

    if "./$script" >"$LOG" 2>&1; then
        rm -f "$LOG"
        echo "✓ PASS: $script"
        sleep 0.2
    else
        echo "✗ FAILED: $script"
        echo
        echo "--- FAILURE ---"
        tail -40 "$LOG" 2>/dev/null || true
        echo "--- END FAILURE ---"
        exit 1
    fi
}

mapfile -t STEPS < <(
    find "$ROOT" -maxdepth 1 -type f -name 'STEP*.sh' -printf '%f\n' 2>/dev/null |
    sort -V
)

if [ "${#STEPS[@]}" -eq 0 ]; then
    echo "NO STEP SCRIPTS FOUND"
    exit 1
fi

for step in "${STEPS[@]}"; do
    run_step "$step"
done

rm -f "$LOG"

clear

echo "=== REQUEST RUNNER® ==="
echo
echo "✓ AUTOMATED BUILD COMPLETE"
echo "✓ ${#STEPS[@]} STEPS PASSED"
echo "✓ TERMINAL CLEAN"
echo "✓ NO PROJECT DATA MODIFIED BY RUNNER"
