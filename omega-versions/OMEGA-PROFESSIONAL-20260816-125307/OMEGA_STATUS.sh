#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd ~/omega

printf '\nOMEGA® STATUS\n'
printf '─────────────\n'
printf 'CLI:    '
test -s bin/omega.js && echo PASS || echo FAIL
printf 'BUILD:  '
test -s .next/BUILD_ID && echo READY || echo MISSING
printf 'CERT:   '
test -s .omega/certification/OMEGA_CERTIFIED.txt && echo CERTIFIED || echo NOT_CERTIFIED
printf 'HTTP:   '
curl -fsS http://127.0.0.1:3000 >/dev/null 2>&1 && echo 200 || echo OFFLINE
printf 'IDEAS:  '
wc -l < inventions/winners.jsonl 2>/dev/null || echo 0
printf '\n'
