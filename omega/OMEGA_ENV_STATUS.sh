#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd "$(dirname "$0")"

echo
echo "============================================================"
echo "OMEGA® — ENVIRONMENT STATUS"
echo "============================================================"
echo

command -v node >/dev/null 2>&1 \
    && echo "PASS  Node.js: $(node --version)" \
    || echo "FAIL  Node.js"

command -v npm >/dev/null 2>&1 \
    && echo "PASS  npm: $(npm --version)" \
    || echo "FAIL  npm"

command -v python >/dev/null 2>&1 \
    && echo "PASS  Python: $(python --version 2>&1)" \
    || echo "FAIL  Python"

test -d node_modules \
    && echo "PASS  node_modules" \
    || echo "FAIL  node_modules"

test -f .env.local \
    && echo "PASS  .env.local" \
    || echo "FAIL  .env.local"

MODEL="$(
    sed -n 's/^OMEGA_GPT_MODEL=//p' .env.local |
    head -n 1
)"

[ -n "$MODEL" ] \
    && echo "PASS  GPT model: $MODEL" \
    || echo "FAIL  GPT model"

if grep -q '^OPENAI_API_KEY=.\+' .env.local; then
    echo "PASS  OpenAI API key configured"
else
    echo "FAIL  OpenAI API key not configured"
fi

echo
echo "NEXT:"
echo "./OMEGA_CONFIGURE_GPT.sh   # only if key is missing"
echo "./OMEGA_DEV.sh             # start application"
echo
