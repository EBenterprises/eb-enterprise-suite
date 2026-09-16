#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo
echo "============================================================"
echo "OMEGA® — DEVELOPMENT RUNTIME"
echo "============================================================"
echo

if [ ! -f ".env.local" ]; then
    echo "FAIL  .env.local missing"
    exit 1
fi

set -a
# Load only the variables required by OMEGA®.
source <(
    python - <<'PY'
from pathlib import Path

for line in Path(".env.local").read_text().splitlines():
    line=line.strip()

    if not line or line.startswith("#") or "=" not in line:
        continue

    key, value = line.split("=", 1)

    if key in ("OPENAI_API_KEY", "OMEGA_GPT_MODEL"):
        print(f'export {key}="{value}"')
PY
)
set +a

export OMEGA_GPT_MODEL="${OMEGA_GPT_MODEL:-gpt-5}"

if [ -z "${OPENAI_API_KEY:-}" ]; then
    echo "FAIL  OPENAI_API_KEY is not configured."
    echo
    echo "Run:"
    echo "./OMEGA_CONFIGURE_GPT.sh"
    echo
    exit 1
fi

echo "PASS  OpenAI credential configured"
echo "PASS  Model: $OMEGA_GPT_MODEL"
echo "PASS  Next.js runtime environment loaded"
echo
echo "Starting OMEGA®..."
echo

exec npm run dev
