#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd ~/omega

OBJECTIVE="${*:-general improvement}"

printf '\n==================================================\n'
printf 'OMEGA® — FAST INVENTION PIPELINE\n'
printf '==================================================\n'

./OMEGA_INVENT_FAST.sh "$OBJECTIVE"
./OMEGA_EVOLVE_FAST.sh

printf '==================================================\n'
printf 'OMEGA® — INVENTION COMPLETE\n'
printf 'CERTIFICATION: NOT RUN\n'
printf '==================================================\n\n'
