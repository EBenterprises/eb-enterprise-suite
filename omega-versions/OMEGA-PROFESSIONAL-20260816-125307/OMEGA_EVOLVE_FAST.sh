#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd ~/omega

G="${OMEGA_GENERATIONS:-3}"
P="${OMEGA_POPULATION:-16}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

printf '\nOMEGA® EVOLVE → '

if OMEGA_GENERATIONS="$G" \
   OMEGA_POPULATION="$P" \
   node engine/invention/evolve.js >"$TMP/out" 2>"$TMP/err"
then
    printf 'PASS\n'
else
    printf 'FAIL\n'
    tail -15 "$TMP/err"
    exit 1
fi

node engine/invention/novelty.js \
    >"$TMP/novelty" 2>"$TMP/novelty.err" || {
    printf 'NOVELTY: FAIL\n'
    tail -15 "$TMP/novelty.err"
    exit 1
}

printf 'GENERATIONS: %s\n' "$G"
printf 'POPULATION:  %s\n' "$P"
printf 'OUTPUT:     inventions/novel-winners.jsonl\n'
printf 'CERTIFY:    NOT RUN\n\n'
