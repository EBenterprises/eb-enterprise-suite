#!/data/data/com.termux/files/usr/bin/bash

ROOT="$HOME/request-runner"

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — LIVE STATUS"
echo "=============================================================="
echo

if [ -f "$ROOT/.completion-engine-state" ]; then
    cat "$ROOT/.completion-engine-state"
else
    echo "status=IDLE"
fi

echo
echo "--------------------------------------------------------------"
echo " ACTIVE COMPLETION PROCESSES"
echo "--------------------------------------------------------------"

ps -ef | grep -E \
'COMPLETION_ENGINE|MASS_COMPLETE|REQUEST_RUNNER_RELEASE_GATE|FINAL_PRODUCTION_SNAPSHOT|next-build|npm run build' |
grep -v grep || true

echo
echo "--------------------------------------------------------------"
echo " DEVELOPMENT SERVICES"
echo "--------------------------------------------------------------"

ps -ef | grep -E \
'realtime-server.js|next dev|next-server' |
grep -v grep || true

echo
echo "--------------------------------------------------------------"
echo " RECENT COMPLETION LOGS"
echo "--------------------------------------------------------------"

ls -1t "$ROOT/.completion-logs" 2>/dev/null | head -5 || true

echo
echo "=============================================================="
