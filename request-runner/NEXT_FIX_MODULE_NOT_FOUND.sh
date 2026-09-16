#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=============================================================="
echo " EB PLATFORM® — MODULE RESOLUTION FINAL FIX"
echo "=============================================================="
echo

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/.module-fix-backup-$STAMP"

echo "[1] BACKUP"
echo "--------------------------------------------------------------"

mkdir -p "$BACKUP"
cp -a app "$BACKUP/app"
cp -a framework "$BACKUP/framework"
cp -p package.json "$BACKUP/package.json"

echo "✓ Backup: $BACKUP"
echo

echo "[2] VERIFY CRUD FILE"
echo "--------------------------------------------------------------"

CRUD="$ROOT/framework/api/crud-route.js"

if [ ! -f "$CRUD" ]; then
    echo "✗ Missing:"
    echo "  $CRUD"
    exit 1
fi

echo "✓ $CRUD exists"
echo

echo "[3] VERIFY NODE RESOLUTION"
echo "--------------------------------------------------------------"

node - <<'NODE'
const fs = require("fs");
const path = require("path");

const routes = [
  "app/api/administration/route.js",
  "app/api/administration/[id]/route.js",
  "app/api/customers/route.js",
  "app/api/customers/[id]/route.js",
  "app/api/drivers/route.js",
  "app/api/drivers/[id]/route.js",
  "app/api/locations/route.js",
  "app/api/locations/[id]/route.js",
  "app/api/notifications/route.js",
  "app/api/notifications/[id]/route.js",
  "app/api/operations/route.js",
  "app/api/operations/[id]/route.js",
  "app/api/orders/route.js",
  "app/api/orders/[id]/route.js",
  "app/api/payments/route.js",
  "app/api/payments/[id]/route.js",
  "app/api/requests/route.js",
  "app/api/requests/[id]/route.js",
  "app/api/scheduling/route.js",
  "app/api/scheduling/[id]/route.js"
];

for (const route of routes) {
  if (!fs.existsSync(route)) {
    throw new Error(`Missing route: ${route}`);
  }

  const source = fs.readFileSync(route, "utf8");

  const match = source.match(
    /require\(["']([^"']*framework\/api\/crud-route)["']\)/
  );

  if (!match) {
    throw new Error(`CRUD import not found: ${route}`);
  }

  const importPath = match[1];

  const resolved = require.resolve(
    path.resolve(path.dirname(route), importPath)
  );

  console.log(`✓ ${route}`);
  console.log(`  ${importPath}`);
  console.log(`  -> ${resolved}`);
}

console.log();
console.log("✓ Node resolves every CRUD route");
NODE

echo

echo "[4] VERIFY CRUD ENGINE LOAD"
echo "--------------------------------------------------------------"

node - <<'NODE'
const crud = require("./framework/api/crud-route");

if (typeof crud !== "function") {
  throw new Error("crud-route default export is not callable");
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

const handlers = crud.createCrudRoute("customers");

for (const method of [
  "GET",
  "POST",
  "PATCH",
  "DELETE"
]) {
  if (typeof handlers[method] !== "function") {
    throw new Error(`Missing handler: ${method}`);
  }
}

console.log("✓ CRUD engine loads");
console.log("✓ GET");
console.log("✓ POST");
console.log("✓ PATCH");
console.log("✓ DELETE");
NODE

echo

echo "[5] VERIFY ROUTE MODULE LOADING"
echo "--------------------------------------------------------------"

node - <<'NODE'
const routes = [
  "app/api/administration/route.js",
  "app/api/administration/[id]/route.js",
  "app/api/customers/route.js",
  "app/api/customers/[id]/route.js",
  "app/api/drivers/route.js",
  "app/api/drivers/[id]/route.js",
  "app/api/locations/route.js",
  "app/api/locations/[id]/route.js",
  "app/api/notifications/route.js",
  "app/api/notifications/[id]/route.js",
  "app/api/operations/route.js",
  "app/api/operations/[id]/route.js",
  "app/api/orders/route.js",
  "app/api/orders/[id]/route.js",
  "app/api/payments/route.js",
  "app/api/payments/[id]/route.js",
  "app/api/requests/route.js",
  "app/api/requests/[id]/route.js",
  "app/api/scheduling/route.js",
  "app/api/scheduling/[id]/route.js"
];

for (const route of routes) {
  try {
    require("./" + route);
    console.log(`✓ ${route}`);
  } catch (error) {
    console.error(`✗ ${route}`);
    console.error(error.stack || error);
    process.exit(1);
  }
}

console.log();
console.log("✓ All route modules load");
NODE

echo

echo "[6] JAVASCRIPT SYNTAX"
echo "--------------------------------------------------------------"

while IFS= read -r -d '' file; do
  if ! node --check "$file" >/dev/null 2>&1; then
    echo "✗ Syntax error: $file"
    node --check "$file"
    exit 1
  fi
done < <(
  find app framework \
    -type f \
    -name '*.js' \
    -print0
)

echo "✓ JavaScript syntax clean"
echo

echo "[7] PACKAGE BUILD COMMAND"
echo "--------------------------------------------------------------"

npm pkg set scripts.build="next build --webpack"

echo "✓ $(npm pkg get scripts.build)"
echo

echo "[8] CLEAN NEXT BUILD"
echo "--------------------------------------------------------------"

rm -rf .next

echo "✓ .next removed"
echo

echo "[9] PRODUCTION WEBPACK BUILD"
echo "--------------------------------------------------------------"

npm run build

echo

echo "[10] VERIFY PRODUCTION ARTIFACT"
echo "--------------------------------------------------------------"

if [ ! -d ".next" ]; then
  echo "✗ .next missing"
  exit 1
fi

if [ ! -f ".next/BUILD_ID" ]; then
  echo "✗ .next/BUILD_ID missing"
  exit 1
fi

echo "✓ .next exists"
echo "✓ BUILD_ID:"
cat .next/BUILD_ID

echo

echo "=============================================================="
echo " EB PLATFORM® — MODULE NOT FOUND RESOLVED"
echo "=============================================================="
echo
echo "✓ Framework CRUD module exists"
echo "✓ Node resolution verified"
echo "✓ All CRUD routes load"
echo "✓ JavaScript syntax verified"
echo "✓ Webpack production build passed"
echo
echo "NEXT:"
echo "  Production server verification"
echo
