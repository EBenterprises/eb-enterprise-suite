#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo
echo "=============================================================="
echo " EB PLATFORM® — REALITY AUDIT"
echo "=============================================================="
echo

echo "[1] PROJECT"
echo "--------------------------------------------------------------"
printf 'Root: %s\n' "$ROOT"
printf 'Node: '; node --version
printf 'NPM : '; npm --version

echo
echo "[2] SOURCE TREE"
echo "--------------------------------------------------------------"
find app apps framework bin tests \
    -type f \
    2>/dev/null |
    sort |
    sed -n '1,300p'

echo
echo "[3] PLACEHOLDERS / MOCKS"
echo "--------------------------------------------------------------"

grep -RInE \
    --exclude-dir=node_modules \
    --exclude-dir=.next \
    --exclude-dir=.git \
    --exclude='*.bak*' \
    'TODO|FIXME|PLACEHOLDER|MOCK|MOCKED|FAKE|STUB|DUMMY|coming soon|not implemented|throw new Error' \
    . 2>/dev/null |
    sed -n '1,300p' || true

echo
echo "[4] STATIC SUCCESS RESPONSES"
echo "--------------------------------------------------------------"

grep -RInE \
    --exclude-dir=node_modules \
    --exclude-dir=.next \
    --exclude-dir=.git \
    'success:[[:space:]]*true|ok:[[:space:]]*true|status:[[:space:]]*"success"|status:[[:space:]]*"ok"' \
    app apps framework server.js realtime-server.js 2>/dev/null |
    sed -n '1,250p' || true

echo
echo "[5] IN-MEMORY STATE"
echo "--------------------------------------------------------------"

grep -RInE \
    --exclude-dir=node_modules \
    --exclude-dir=.next \
    --exclude-dir=.git \
    'let [A-Za-z_]+[[:space:]]*=[[:space:]]*\[\]|const [A-Za-z_]+[[:space:]]*=[[:space:]]*\[\]|new Map\(|new Set\(' \
    app apps framework server.js realtime-server.js 2>/dev/null |
    sed -n '1,250p' || true

echo
echo "[6] API / ROUTES"
echo "--------------------------------------------------------------"

find app -type f \
    \( -name 'route.js' -o -name 'route.ts' -o -name 'route.tsx' \) \
    -print 2>/dev/null |
    sort

echo
echo "[7] DATABASE / PERSISTENCE"
echo "--------------------------------------------------------------"

find . \
    -path './node_modules' -prune -o \
    -path './.next' -prune -o \
    -type f \
    \( \
        -name '*.db' \
        -o -name '*.sqlite' \
        -o -name '*.sqlite3' \
        -o -name 'schema.prisma' \
        -o -name '*migration*' \
        -o -name '*repository*' \
    \) \
    -print 2>/dev/null |
    sort

echo
echo "[8] DEPENDENCIES"
echo "--------------------------------------------------------------"

node - <<'NODE'
const pkg = require("./package.json");

console.log("dependencies:");
for (const [name, version] of Object.entries(pkg.dependencies || {})) {
    console.log(`  ${name}: ${version}`);
}

console.log();
console.log("devDependencies:");
for (const [name, version] of Object.entries(pkg.devDependencies || {})) {
    console.log(`  ${name}: ${version}`);
}
NODE

echo
echo "[9] FRAMEWORK EXPORTS"
echo "--------------------------------------------------------------"

node - <<'NODE'
const platform = require("./framework");

for (const [name, value] of Object.entries(platform)) {
    console.log(
        `${name}: ${typeof value}${value?.constructor?.name ? ` (${value.constructor.name})` : ""}`
    );
}
NODE

echo
echo "[10] APPLICATION MODULES"
echo "--------------------------------------------------------------"

node - <<'NODE'
const modules = require("./apps/request-runner");

for (const module of modules) {
    console.log(
        `${module.name}: ${Object.keys(module).join(", ")}`
    );
}
NODE

echo
echo "[11] LIVE SERVICES"
echo "--------------------------------------------------------------"

echo "3000:"
curl -sS -o /dev/null -w '  HTTP %{http_code}\n' \
    --max-time 5 \
    http://127.0.0.1:3000/request \
    || true

echo "3001:"
curl -sS \
    --max-time 5 \
    "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
    2>/dev/null |
    head -c 300 || true

echo

echo
echo "[12] JAVASCRIPT SYNTAX"
echo "--------------------------------------------------------------"

FAILED=0

while IFS= read -r file; do
    case "$file" in
        ./node_modules/*|./.next/*|./.git/*)
            continue
            ;;
    esac

    if ! node --check "$file" >/dev/null 2>&1; then
        echo "✗ $file"
        FAILED=1
    fi
done < <(
    find app apps framework bin tests \
        -type f \
        -name '*.js' \
        2>/dev/null |
        sort
)

if [ "$FAILED" -eq 0 ]; then
    echo "✓ Syntax clean"
fi

echo
echo "[13] GIT STATE"
echo "--------------------------------------------------------------"

if [ -d .git ]; then
    git status --short
else
    echo "No local Git repository detected"
fi

echo
echo "=============================================================="
echo " REALITY AUDIT COMPLETE"
echo " NO FILES MODIFIED"
echo "=============================================================="
