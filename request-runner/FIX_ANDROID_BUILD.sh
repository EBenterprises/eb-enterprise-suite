#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=============================================================="
echo " EB PLATFORM® — ANDROID PRODUCTION BUILD FIX"
echo "=============================================================="
echo

echo "[1] BACKUP CONFIG"
echo "--------------------------------------------------------------"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/.build-backup-$STAMP"
mkdir -p "$BACKUP"

[ -f next.config.js ] && cp -p next.config.js "$BACKUP/next.config.js" || true
[ -f package.json ] && cp -p package.json "$BACKUP/package.json" || true

echo "✓ Backup: $BACKUP"
echo

echo "[2] VERIFY NEXT VERSION"
echo "--------------------------------------------------------------"

node - <<'NODE'
const pkg = require("./package.json");
console.log("Next:", pkg.dependencies?.next || pkg.devDependencies?.next || "missing");
console.log("Node:", process.version);
console.log("Platform:", process.platform);
console.log("Architecture:", process.arch);
NODE

echo

echo "[3] FORCE WEBPACK FOR ANDROID"
echo "--------------------------------------------------------------"

node - <<'NODE'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

pkg.scripts ||= {};

const existingBuild = pkg.scripts.build || "next build";

if (!existingBuild.includes("--webpack")) {
    pkg.scripts.build = existingBuild.replace(
        /^next build$/,
        "next build --webpack"
    );
}

if (!pkg.scripts.build.includes("--webpack")) {
    pkg.scripts.build = "next build --webpack";
}

fs.writeFileSync(
    file,
    JSON.stringify(pkg, null, 2) + "\n"
);

console.log("Build command:", pkg.scripts.build);
NODE

echo "✓ Production build configured for Webpack"
echo

echo "[4] VERIFY PACKAGE"
echo "--------------------------------------------------------------"

npm pkg get scripts.build

echo

echo "[5] CLEAN BUILD ARTIFACT"
echo "--------------------------------------------------------------"

rm -rf .next

echo "✓ .next removed"
echo

echo "[6] PRODUCTION BUILD"
echo "--------------------------------------------------------------"

npm run build

echo
echo "✓ Production build completed"
echo

echo "[7] PRODUCTION ARTIFACT"
echo "--------------------------------------------------------------"

if [ ! -d ".next" ]; then
    echo "✗ .next was not created"
    exit 1
fi

if [ ! -f ".next/BUILD_ID" ]; then
    echo "✗ BUILD_ID missing"
    exit 1
fi

echo "✓ .next exists"
echo "✓ BUILD_ID:"
cat .next/BUILD_ID
echo

echo "[8] START PRODUCTION SERVER"
echo "--------------------------------------------------------------"

RUNTIME="$ROOT/.runtime"
mkdir -p "$RUNTIME"

PID="$RUNTIME/next-production.pid"
LOG="$RUNTIME/next-production.log"

if [ -f "$PID" ]; then
    OLD_PID="$(cat "$PID" 2>/dev/null || true)"

    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Stopping previous production server: $OLD_PID"
        kill "$OLD_PID" 2>/dev/null || true
        sleep 2
    fi
fi

rm -f "$PID"
: > "$LOG"

nohup npm run start -- --hostname 127.0.0.1 --port 3010 \
    >> "$LOG" 2>&1 &

echo $! > "$PID"

echo "Production PID: $(cat "$PID")"

echo
echo "Waiting for production server..."

READY=0

for _ in $(seq 1 30); do
    if curl -fsS --max-time 2 \
        http://127.0.0.1:3010/request \
        >/dev/null 2>&1; then
        READY=1
        break
    fi

    sleep 1
done

if [ "$READY" -ne 1 ]; then
    echo
    echo "✗ Production server failed"
    echo
    tail -n 100 "$LOG" || true
    exit 1
fi

echo "✓ Production server healthy"
echo

echo "[9] PRODUCTION HTTP TESTS"
echo "--------------------------------------------------------------"

check_http() {
    local name="$1"
    local url="$2"

    local code

    code="$(curl -sS -o /dev/null -w '%{http_code}' \
        --max-time 5 "$url")"

    printf '%-24s HTTP %s\n' "$name" "$code"

    case "$code" in
        2??|3??)
            ;;
        *)
            echo "✗ $name failed"
            return 1
            ;;
    esac
}

check_http "Customer Request" \
    "http://127.0.0.1:3010/request"

check_http "Operations" \
    "http://127.0.0.1:3010/ops"

echo

echo "[10] HEALTH API"
echo "--------------------------------------------------------------"

HEALTH="$(curl -fsS --max-time 5 \
    http://127.0.0.1:3010/api/health)"

printf '%s\n' "$HEALTH" | head -c 1000
echo

echo

echo "[11] REAL PERSISTENCE CHECK"
echo "--------------------------------------------------------------"

node - <<'NODE'
const platform = require("./framework");

if (!platform.JsonRepository) {
    throw new Error("JsonRepository export missing");
}

const repo = new platform.JsonRepository(
    ".runtime/reality-production-test"
);

(async () => {
    const id = `production-${Date.now()}`;

    await repo.create({
        id,
        type: "production-verification",
        value: "durable"
    });

    const found = await repo.findById(id);

    if (!found || found.value !== "durable") {
        throw new Error("Persistence CREATE/READ failed");
    }

    await repo.update(id, {
        value: "updated"
    });

    const updated = await repo.findById(id);

    if (!updated || updated.value !== "updated") {
        throw new Error("Persistence UPDATE failed");
    }

    await repo.delete(id);

    const deleted = await repo.findById(id);

    if (deleted) {
        throw new Error("Persistence DELETE failed");
    }

    console.log("✓ Persistent CREATE");
    console.log("✓ Persistent READ");
    console.log("✓ Persistent UPDATE");
    console.log("✓ Persistent DELETE");
    console.log("✓ Durable persistence verified");
})().catch(err => {
    console.error(err);
    process.exit(1);
});
NODE

echo

echo "[12] PRODUCTION LOG"
echo "--------------------------------------------------------------"

tail -n 50 "$LOG" || true

echo
echo "=============================================================="
echo " REALITY BUILD PASSED"
echo "=============================================================="
echo
echo "Production:"
echo "  http://127.0.0.1:3010/request"
echo
echo "Health:"
echo "  http://127.0.0.1:3010/api/health"
echo
echo "The Android build now uses Webpack instead of Turbopack."
echo
