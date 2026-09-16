#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

STATE=".completion-state/universal-fabric"
REPORTS="$STATE/reports"

mkdir -p "$REPORTS"

while true; do

    clear

    echo "=============================================================="
    echo " COMPLETION ENGINE® — CONTINUOUS CONVERGENCE"
    echo "=============================================================="

    ###########################################################################
    # RESOURCE STATUS
    ###########################################################################

    RAM="$(
        awk '/MemAvailable:/ {
            printf "%d", $2/1024
            exit
        }' /proc/meminfo 2>/dev/null || echo 0
    )"

    DISK="$(
        df -Pm . 2>/dev/null |
        awk 'NR==2 {print $4}'
    )"

    echo "RAM AVAILABLE : ${RAM}MB"
    echo "DISK AVAILABLE: ${DISK:-0}MB"

    ###########################################################################
    # NODE
    ###########################################################################

    if ! command -v node >/dev/null 2>&1; then
        echo "⚠ Node unavailable"
        sleep 5
        continue
    fi

    echo "NODE          : $(node --version)"

    ###########################################################################
    # NEXT
    ###########################################################################

    if [ ! -x node_modules/.bin/next ]; then
        echo "⚠ Next.js missing — repairing"

        npm install \
            --no-audit \
            --no-fund \
            --ignore-scripts \
            > "$REPORTS/continuous-npm.log" 2>&1 || true

        sleep 2
        continue
    fi

    echo "NEXT          : $(node_modules/.bin/next --version 2>/dev/null)"

    ###########################################################################
    # BUILD ARTIFACT
    ###########################################################################

    if [ ! -d .next/server ]; then

        echo
        echo "⚠ SERVER ARTIFACT MISSING"
        echo "→ REBUILDING WITH WEBPACK"

        rm -rf .next

        if node_modules/.bin/next build --webpack \
            > "$REPORTS/continuous-build.log" 2>&1
        then
            echo "✓ BUILD COMPLETE"
        else
            echo "✗ BUILD FAILED"
            echo
            tail -60 "$REPORTS/continuous-build.log"
            sleep 5
            continue
        fi
    fi

    ###########################################################################
    # SERVER VERIFICATION
    ###########################################################################

    if [ -d .next/server ]; then
        SERVER="PASS"
    else
        SERVER="FAIL"
    fi

    echo
    echo "SERVER ARTIFACT: $SERVER"

    ###########################################################################
    # MANIFEST CHECK
    ###########################################################################

    MANIFESTS=0

    for f in \
        .next/server/app-paths-manifest.json \
        .next/server/pages-manifest.json \
        .next/server/middleware-manifest.json
    do
        if [ -f "$f" ]; then
            MANIFESTS=$((MANIFESTS + 1))
        fi
    done

    echo "MANIFESTS       : $MANIFESTS"

    ###########################################################################
    # STATUS
    ###########################################################################

    if [ "$SERVER" = "PASS" ]; then
        STATUS="HEALTHY"
    else
        STATUS="REPAIRING"
    fi

    cat > "$STATE/continuous-status.json" <<JSON
{
  "engine": "COMPLETION ENGINE®",
  "mode": "CONTINUOUS",
  "status": "$STATUS",
  "server_artifact": "$SERVER",
  "manifests": $MANIFESTS,
  "timestamp": "$(date -Iseconds)"
}
JSON

    echo
    echo "STATUS          : $STATUS"
    echo "MODE            : CONTINUOUS"
    echo "PROCESS         : ACTIVE"
    echo
    echo "✓ Completion does NOT terminate the process."
    echo "✓ Monitoring continues."
    echo "✓ Repair loop remains active."

    sleep 10

done
