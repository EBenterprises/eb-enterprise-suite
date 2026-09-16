#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$HOME/request-runner"
cd "$ROOT"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".crud-alias-backup-$STAMP"

echo "=============================================================="
echo " EB PLATFORM® — CRUD MODULE RESOLUTION REPAIR"
echo "=============================================================="

mkdir -p "$BACKUP"

cp -a app "$BACKUP/app"
cp -a framework "$BACKUP/framework"
cp -p next.config.js "$BACKUP/next.config.js" 2>/dev/null || true
cp -p jsconfig.json "$BACKUP/jsconfig.json" 2>/dev/null || true
cp -p package.json "$BACKUP/package.json"

echo "✓ Backup: $BACKUP"
echo

echo "[1] CREATE PROJECT ROOT ALIAS"
echo "--------------------------------------------------------------"

cat > jsconfig.json <<'JSON'
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./*"],
      "@framework/*": ["./framework/*"],
      "@app/*": ["./app/*"]
    }
  },
  "exclude": [
    "node_modules",
    ".next"
  ]
}
JSON

echo "✓ jsconfig.json created"
echo

echo "[2] REPAIR ALL CRUD IMPORTS"
echo "--------------------------------------------------------------"

for collection in \
    administration \
    customers \
    drivers \
    locations \
    notifications \
    operations \
    orders \
    payments \
    requests \
    scheduling
do

    BASE="app/api/$collection/route.js"
    ID="app/api/$collection/[id]/route.js"

    if [ -f "$BASE" ]; then
        sed -i \
            -E 's#require\(["'\''][^"'\'']*crud-route["'\'']\)#require("@framework/api/crud-route")#g' \
            "$BASE"

        echo "✓ $BASE"
    fi

    if [ -f "$ID" ]; then
        sed -i \
            -E 's#require\(["'\''][^"'\'']*crud-route["'\'']\)#require("@framework/api/crud-route")#g' \
            "$ID"

        echo "✓ $ID"
    fi

done

echo

echo "[3] SHOW RESULTING IMPORTS"
echo "--------------------------------------------------------------"

grep -RIn \
    --include='route.js' \
    'crud-route' \
    app/api |
    sort

echo

echo "[4] VERIFY CRUD ENGINE"
echo "--------------------------------------------------------------"

test -f framework/api/crud-route.js

node --check framework/api/crud-route.js

node <<'NODE'
const crud = require("./framework/api/crud-route");

if (typeof crud !== "function") {
    throw new Error("CRUD engine is not callable");
}

for (const name of [
    "createCrudRoute",
    "crudRoute",
    "createCollectionHandlers"
]) {
    if (typeof crud[name] !== "function") {
        throw new Error(`Missing export: ${name}`);
    }
}

console.log("✓ CRUD engine loads");
console.log("✓ CRUD exports valid");
NODE

echo

echo "[5] UPDATE NEXT CONFIG WITH ALIAS"
echo "--------------------------------------------------------------"

cat > next.config.js <<'JS'
/** @type {import('next').NextConfig} */

const nextConfig = {
    allowedDevOrigins: [
        "127.0.0.1",
        "localhost",
        "192.168.1.188"
    ],

    webpack: (config) => {
        config.resolve.alias = {
            ...(config.resolve.alias || {}),
            "@framework": require("path").resolve(
                __dirname,
                "framework"
            ),
            "@app": require("path").resolve(
                __dirname,
                "app"
            ),
            "@": require("path").resolve(
                __dirname
            )
        };

        return config;
    }
};

module.exports = nextConfig;
JS

echo "✓ Next.js aliases configured"
echo

echo "[6] VERIFY ROUTE SOURCE"
echo "--------------------------------------------------------------"

BAD=0

while IFS= read -r -d '' file; do
    if grep -q 'crud-route' "$file"; then
        if ! grep -q '@framework/api/crud-route' "$file"; then
            echo "✗ Wrong CRUD import: $file"
            BAD=1
        else
            echo "✓ $file"
        fi
    fi
done < <(
    find app/api \
        -type f \
        -name 'route.js' \
        -print0
)

if [ "$BAD" -ne 0 ]; then
    exit 1
fi

echo

echo "[7] VERIFY APPLICATION SERVICE"
echo "--------------------------------------------------------------"

node <<'NODE'
const service = require("./framework/application-service");

for (const method of [
    "repository",
    "list",
    "get",
    "create",
    "update",
    "remove"
]) {
    if (typeof service[method] !== "function") {
        throw new Error(
            `Missing application-service.${method}`
        );
    }

    console.log(`✓ ${method}`);
}
NODE

echo

echo "[8] CLEAN GENERATED BUILD"
echo "--------------------------------------------------------------"

rm -rf .next

echo "✓ .next removed"
echo

echo "[9] FORCE WEBPACK"
echo "--------------------------------------------------------------"

npm pkg set scripts.build="next build --webpack"

echo "✓ $(npm pkg get scripts.build)"
echo

echo "[10] PRODUCTION BUILD"
echo "--------------------------------------------------------------"

npm run build

echo

echo "[11] VERIFY ARTIFACT"
echo "--------------------------------------------------------------"

test -d .next
test -f .next/BUILD_ID

echo "✓ .next exists"
echo "✓ BUILD_ID: $(cat .next/BUILD_ID)"

echo
echo "=============================================================="
echo " EB PLATFORM® — MODULE RESOLUTION FIX PASSED"
echo "=============================================================="
