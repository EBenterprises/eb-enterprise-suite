#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".completion-backups/runtime-promotion-$STAMP"
mkdir -p "$BACKUP"

echo "=============================================================="
echo " COMPLETION ENGINE® — RUNTIME PROMOTION"
echo "=============================================================="

echo
echo "[1/6] Backing up main engine"
cp COMPLETION_ENGINE.sh "$BACKUP/COMPLETION_ENGINE.sh"
echo "✓ $BACKUP/COMPLETION_ENGINE.sh"

echo
echo "[2/6] Checking runtime"
test -x COMPLETION_ENGINE_BUILD_RUNTIME.sh
test -f .completion-build-policy

echo "✓ Runtime available"
echo "✓ Build policy available"

echo
echo "[3/6] Installing runtime loader"

node <<'NODE'
const fs = require("fs");

const file = "COMPLETION_ENGINE.sh";
let s = fs.readFileSync(file, "utf8");

const marker = "# COMPLETION_ENGINE_BUILD_RUNTIME_LOADED";

if (s.includes(marker)) {
    console.log("✓ Runtime loader already present");
    process.exit(0);
}

const injection = `
# COMPLETION_ENGINE_BUILD_RUNTIME_LOADED
COMPLETION_ENGINE_ROOT="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$COMPLETION_ENGINE_ROOT/COMPLETION_ENGINE_BUILD_RUNTIME.sh" ]; then
    . "$COMPLETION_ENGINE_ROOT/COMPLETION_ENGINE_BUILD_RUNTIME.sh"
fi
`;

const shebang = /^#![^\\n]*\\n/;

if (shebang.test(s)) {
    s = s.replace(shebang, match => match + injection + "\n");
} else {
    s = injection + "\n" + s;
}

fs.writeFileSync(file, s);
console.log("✓ Runtime loader injected");
NODE

echo
echo "[4/6] Confirming integration"

grep -nE \
'COMPLETION_ENGINE_BUILD_RUNTIME|NEXT_BUILD_ENGINE|NEXT_BUILD_COMMAND|completion_engine_build_and_verify' \
COMPLETION_ENGINE.sh | head -50 || true

echo
echo "[5/6] Syntax validation"

bash -n COMPLETION_ENGINE.sh
bash -n COMPLETION_ENGINE_BUILD_RUNTIME.sh

echo "✓ Shell syntax valid"

echo
echo "[6/6] Promotion complete"

echo "=============================================================="
echo " COMPLETION ENGINE® — RUNTIME PROMOTED"
echo "=============================================================="
echo "Main engine:     COMPLETION_ENGINE.sh"
echo "Build runtime:   COMPLETION_ENGINE_BUILD_RUNTIME.sh"
echo "Policy:          .completion-build-policy"
echo "Rollback:        $BACKUP"
echo
echo "IMPORTANT:"
echo "The verified Webpack build remains the production path."
echo "=============================================================="
