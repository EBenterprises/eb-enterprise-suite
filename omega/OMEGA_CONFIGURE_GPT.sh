#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd "$(dirname "$0")"

touch .env.local

echo
echo "============================================================"
echo "OMEGA® — GPT CREDENTIAL CONFIGURATION"
echo "============================================================"
echo
echo "Enter your OpenAI API key."
echo "The key will not be displayed while entering it."
echo

read -r -s -p "OPENAI_API_KEY: " API_KEY
echo

if [ -z "$API_KEY" ]; then
    echo
    echo "FAIL  API key was empty."
    exit 1
fi

python - "$API_KEY" <<'PY'
from pathlib import Path
import sys

key = sys.argv[1]

p = Path(".env.local")
lines = p.read_text().splitlines()

out = []
found = False

for line in lines:
    if line.startswith("OPENAI_API_KEY="):
        if not found:
            out.append("OPENAI_API_KEY=" + key)
            found = True
        continue

    out.append(line)

if not found:
    out.append("OPENAI_API_KEY=" + key)

if not any(line.startswith("OMEGA_GPT_MODEL=") for line in out):
    out.append("OMEGA_GPT_MODEL=gpt-5")

p.write_text("\n".join(out) + "\n")
PY

chmod 600 .env.local

echo
echo "PASS  API key stored in .env.local"
echo "PASS  .env.local permissions restricted"
echo "PASS  GPT model configured"
echo
echo "The secret itself was not printed."
