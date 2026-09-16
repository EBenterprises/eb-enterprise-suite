#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$HOME/request-runner"
cd "$ROOT"

echo "=== REQUEST RUNNER® — RELEASE GATE REPAIR ==="

# ------------------------------------------------------------
# 1. FIX RELEASE GATE TEMP PATH
# ------------------------------------------------------------

python_cmd=""
if command -v python >/dev/null 2>&1; then
    python_cmd="python"
elif command -v python3 >/dev/null 2>&1; then
    python_cmd="python3"
fi

if [ -n "$python_cmd" ]; then
    "$python_cmd" - <<'PY'
from pathlib import Path

p = Path("REQUEST_RUNNER_RELEASE_GATE.sh")
s = p.read_text()

s = s.replace(
    'MASS_COMPLETE_REQUEST_RUNNER.sh >/tmp/rr-release-verify.log 2>&1',
    'MASS_COMPLETE_REQUEST_RUNNER.sh >"$ROOT/.release-verify.log" 2>&1'
)

s = s.replace(
    'tail -30 /tmp/rr-release-verify.log',
    'tail -30 "$ROOT/.release-verify.log"'
)

p.write_text(s)
PY
else
    sed -i \
      's#MASS_COMPLETE_REQUEST_RUNNER.sh >/tmp/rr-release-verify.log 2>&1#MASS_COMPLETE_REQUEST_RUNNER.sh >"$ROOT/.release-verify.log" 2>\&1#' \
      REQUEST_RUNNER_RELEASE_GATE.sh

    sed -i \
      's#tail -30 /tmp/rr-release-verify.log#tail -30 "$ROOT/.release-verify.log"#' \
      REQUEST_RUNNER_RELEASE_GATE.sh
fi

chmod 700 REQUEST_RUNNER_RELEASE_GATE.sh

echo "✓ Release gate temp path repaired"

# ------------------------------------------------------------
# 2. FIX LAN IP DETECTION
# ------------------------------------------------------------

if [ -n "$python_cmd" ]; then
    "$python_cmd" - <<'PY'
from pathlib import Path

p = Path("EB_PLATFORM.sh")
s = p.read_text()

old = '''ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++) if(\\\\$i==\\"src\\") {print \\\\$(i+1); exit}}' '''

new = '''ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}' '''

if old in s:
    s = s.replace(old, new)

# Also repair any currently malformed escaped form.
s = s.replace(
    '''awk '/src/ {for(i=1;i<=NF;i++) if(\\\\$i==\\"src\\") {print \\\\$(i+1); exit}}' ''',
    '''awk '/src/ {for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}' '''
)

p.write_text(s)
PY
else
    sed -i \
      's/if(\\\\$i==\\"src\\") {print \\\\$(i+1); exit}/if($i=="src") {print $(i+1); exit}/' \
      EB_PLATFORM.sh
fi

chmod 700 EB_PLATFORM.sh

echo "✓ LAN detection repaired"

# ------------------------------------------------------------
# 3. SYNTAX CHECK
# ------------------------------------------------------------

echo "[1] SHELL SYNTAX"

bash -n EB_PLATFORM.sh || {
    echo "✗ EB_PLATFORM.sh syntax failed"
    exit 1
}

bash -n REQUEST_RUNNER_RELEASE_GATE.sh || {
    echo "✗ REQUEST_RUNNER_RELEASE_GATE.sh syntax failed"
    exit 1
}

echo "✓ EB_PLATFORM.sh"
echo "✓ REQUEST_RUNNER_RELEASE_GATE.sh"

# ------------------------------------------------------------
# 4. STATUS CHECK
# ------------------------------------------------------------

echo
echo "[2] PLATFORM STATUS"

./EB_PLATFORM.sh status

# ------------------------------------------------------------
# 5. RELEASE GATE
# ------------------------------------------------------------

echo
echo "[3] RELEASE GATE"

./REQUEST_RUNNER_RELEASE_GATE.sh

echo
echo "=============================================================="
echo " REQUEST RUNNER® — REPAIR COMPLETE"
echo "=============================================================="
echo "STATUS: GREEN"
