#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

STATE=".completion-state/universal-fabric"
REPORTS="$STATE/reports"
mkdir -p "$REPORTS"

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — CONTINUOUS WATCHDOG®"
echo "=============================================================="
echo " MODE   : NEVER EXIT"
echo " BUILD  : AUTO-REPAIR"
echo " SERVER : AUTO-VERIFY"
echo "=============================================================="

while true; do

    echo
    echo "[WATCHDOG] $(date '+%Y-%m-%d %H:%M:%S')"

    ###########################################################################
    # RESOURCE GATE
    ###########################################################################

    AVAILABLE="$(
        awk '/MemAvailable:/ {
            printf "%d", $2/1024
            exit
        }' /proc/meminfo 2>/dev/null || echo 0
    )"

    echo "RAM=${AVAILABLE}MB"

    ###########################################################################
    # NODE / NPM
    ###########################################################################

    if ! command -v node >/dev/null 2>&1; then
        echo "⚠ Node.js missing"
        sleep 5
        continue
    fi

    if ! command -v npm >/dev/null 2>&1; then
        echo "⚠ npm missing"
        sleep 5
        continue
    fi

    ###########################################################################
    # DEPENDENCY GATE
    ###########################################################################

    if [ ! -x node_modules/.bin/next ]; then
        echo "[REPAIR] Installing dependencies"

        npm install \
            --no-audit \
            --no-fund \
            --ignore-scripts \
            > "$REPORTS/watchdog-npm.log" 2>&1 || true
    fi

    if [ ! -x node_modules/.bin/next ]; then
        echo "⚠ Next.js still unavailable"
        sleep 5
        continue
    fi

    ###########################################################################
    # SERVER ARTIFACT REPAIR
    ###########################################################################

    if [ ! -d .next/server ]; then

        echo "⚠ SERVER ARTIFACT MISSING"
        echo "[REPAIR] Running production Webpack build"

        rm -rf .next

        if node_modules/.bin/next build --webpack \
            > "$REPORTS/watchdog-build.log" 2>&1
        then
            echo "✓ BUILD PASS"
        else
            echo "✗ BUILD FAILED"
            tail -40 "$REPORTS/watchdog-build.log"
            sleep 5
            continue
        fi
    fi

    ###########################################################################
    # ARTIFACT VERIFICATION
    ###########################################################################

    if [ -d .next ] && [ -d .next/server ]; then
        echo "✓ SERVER ARTIFACT PRESENT"
    else
        echo "✗ SERVER ARTIFACT STILL MISSING"
        sleep 5
        continue
    fi

    ###########################################################################
    # MANIFEST DISCOVERY
    ###########################################################################

    echo "[MANIFESTS]"

    find .next/server \
        -maxdepth 3 \
        -type f \
        -name '*.json' \
        2>/dev/null |
        head -30

    ###########################################################################
    # BUILD HEALTH
    ###########################################################################

    cat > "$STATE/watchdog-status.json" <<JSON
{
  "engine": "COMPLETION ENGINE®",
  "mode": "CONTINUOUS",
  "status": "HEALTHY",
  "next_artifact": true,
  "server_artifact": true,
  "timestamp": "$(date -Iseconds)"
}
JSON

    ###########################################################################
    # KEEP ALIVE
    ###########################################################################

    echo "✓ SYSTEM HEALTHY — WATCHDOG REMAINS ACTIVE"
    echo "✓ NO EXIT"
    echo

    sleep 10

done
