#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

OBJECTIVE="${*:-general improvement}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

printf '\nOMEGA® INVENT → '

if node engine/invention/invention-loop.js "$OBJECTIVE" \
    >"$TMP/out" 2>"$TMP/err"; then
    printf 'PASS\n'
else
    printf 'FAIL\n'
    tail -15 "$TMP/err"
    exit 1
fi

RESULT="$(tail -1 "$TMP/out" 2>/dev/null || true)"

printf 'OBJECTIVE: %s\n' "$OBJECTIVE"
printf 'RESULT:    %s\n' "$RESULT"
printf 'OUTPUT:    inventions/winners.jsonl\n'
printf 'CERTIFY:   NOT RUN\n\n'
