#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/.crud-contract-backup-$STAMP"

echo "=============================================================="
echo " EB PLATFORM® — CRUD ROUTE CONTRACT REPAIR"
echo "=============================================================="
echo

echo "[1] BACKUP"
echo "--------------------------------------------------------------"

mkdir -p "$BACKUP"

cp -a app "$BACKUP/app"
cp -a framework "$BACKUP/framework"
cp -p package.json "$BACKUP/package.json"
cp -p next.config.js "$BACKUP/next.config.js" 2>/dev/null || true
cp -p jsconfig.json "$BACKUP/jsconfig.json" 2>/dev/null || true

echo "✓ Backup: $BACKUP"
echo

echo "[2] INSPECT CRUD ENGINE EXPORTS"
echo "--------------------------------------------------------------"

node <<'NODE'
const crud = require("./framework/api/crud-route");

console.log("Default:", typeof crud);

for (const name of [
  "createCrudRoute",
  "crudRoute",
  "createCollectionHandlers",
  "json",
  "readBody"
]) {
  console.log(`${name}: ${typeof crud[name]}`);
}
NODE

echo

echo "[3] CREATE COMPATIBILITY EXPORTS"
echo "--------------------------------------------------------------"

node <<'NODE'
const fs = require("fs");

const file = "framework/api/crud-route.js";
let source = fs.readFileSync(file, "utf8");

if (!source.includes("createCrudHandlers")) {
  source += `

/*
 * EB PLATFORM® CRUD compatibility contract.
 *
 * Route modules use:
 *   createCrudHandlers(collection)
 *   createIdHandlers(collection)
 *
 * Preserve the existing CRUD implementation and expose
 * explicit collection/id handler factories.
 */

function createCrudHandlers(collection) {
    const handlers = createCrudRoute(collection);

    return {
        GET: handlers.GET,
        POST: handlers.POST
    };
}

function createIdHandlers(collection) {
    const handlers = createCrudRoute(collection);

    return {
        GET: handlers.GET,
        PATCH: handlers.PATCH,
        DELETE: handlers.DELETE
    };
}

module.exports.createCrudHandlers = createCrudHandlers;
module.exports.createIdHandlers = createIdHandlers;
`;

  fs.writeFileSync(file, source);
  console.log("✓ Compatibility exports added");
} else {
  console.log("✓ Compatibility exports already present");
}
NODE

echo

echo "[4] VERIFY CRUD CONTRACT"
echo "--------------------------------------------------------------"

node <<'NODE'
const crud = require("./framework/api/crud-route");

for (const name of [
  "createCrudRoute",
  "crudRoute",
  "createCollectionHandlers",
  "createCrudHandlers",
  "createIdHandlers"
]) {
  if (typeof crud[name] !== "function") {
    throw new Error(`Missing CRUD export: ${name}`);
  }

  console.log(`✓ ${name}`);
}

const collection = crud.createCrudHandlers("customers");
const id = crud.createIdHandlers("customers");

for (const method of ["GET", "POST"]) {
  if (typeof collection[method] !== "function") {
    throw new Error(`Missing collection handler: ${method}`);
  }

  console.log(`✓ collection ${method}`);
}

for (const method of ["GET", "PATCH", "DELETE"]) {
  if (typeof id[method] !== "function") {
    throw new Error(`Missing ID handler: ${method}`);
  }

  console.log(`✓ ID ${method}`);
}

console.log("✓ CRUD route contract valid");
NODE

echo

echo "[5] REMOVE NODE-INCOMPATIBLE ALIAS DEPENDENCY"
echo "--------------------------------------------------------------"

python3 - <<'PY'
from pathlib import Path

root = Path("app/api")

for file in root.rglob("route.js"):
    text = file.read_text()

    if "@framework/api/crud-route" not in text:
        continue

    text = text.replace(
        'require("@framework/api/crud-route")',
        'require("../../../../framework/api/crud-route")'
    )

    # Collection routes are one directory shallower.
    if "/[id]/" not in str(file):
        text = text.replace(
            'require("../../../../framework/api/crud-route")',
            'require("../../../framework/api/crud-route")'
        )

    file.write_text(text)
    print(f"✓ {file}")
PY

echo

echo "[6] VERIFY ACTUAL NODE RESOLUTION"
echo "--------------------------------------------------------------"

node <<'NODE'
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
  const source = fs.readFileSync(route, "utf8");

  const match = source.match(
    /require\(["']([^"']*framework\/api\/crud-route)["']\)/
  );

  if (!match) {
    throw new Error(`CRUD import missing: ${route}`);
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

echo "[7] LOAD EVERY ROUTE"
echo "--------------------------------------------------------------"

node <<'NODE'
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
    const mod = require("./" + route);

    const keys = Object.keys(mod);

    if (!keys.length) {
      throw new Error("Route exports nothing");
    }

    console.log(`✓ ${route}: ${keys.join(", ")}`);
  } catch (error) {
    console.error(`✗ ${route}`);
    console.error(error.stack || error);
    process.exit(1);
  }
}

console.log();
console.log("✓ ALL ROUTE MODULES LOAD");
NODE

echo

echo "[8] APPLICATION SERVICE"
echo "--------------------------------------------------------------"

node <<'NODE'
const service = require("./framework/application-service");

for (const name of [
  "repository",
  "list",
  "get",
  "create",
  "update",
  "remove"
]) {
  if (typeof service[name] !== "function") {
    throw new Error(`Missing application-service.${name}`);
  }

  console.log(`✓ ${name}`);
}
NODE

echo

echo "[9] JAVASCRIPT SYNTAX"
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

echo "[10] CLEAN GENERATED BUILD ONLY"
echo "--------------------------------------------------------------"

rm -rf .next

echo "✓ .next removed"
echo "✓ Source preserved"
echo "✓ Framework preserved"
echo "✓ Persistence preserved"
echo

echo "[11] FORCE WEBPACK"
echo "--------------------------------------------------------------"

npm pkg set scripts.build="next build --webpack"

echo "✓ Build: $(npm pkg get scripts.build)"
echo

echo "=============================================================="
echo " EB PLATFORM® — CONTRACT REPAIR PASSED"
echo "=============================================================="
echo
echo "The route contract is now:"
echo
echo "  Collection:"
echo "    GET"
echo "    POST"
echo
echo "  Record:"
echo "    GET"
echo "    PATCH"
echo "    DELETE"
echo
echo "Next step:"
echo "  npm run build"
echo
echo "BACKUP:"
echo "  $BACKUP"
