#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=============================================================="
echo " EB PLATFORM® — NEXT ROUTE CONTRACT DIAGNOSTIC"
echo "=============================================================="
echo

echo "[1] PROJECT"
echo "--------------------------------------------------------------"
pwd
echo "Node: $(node -v)"
echo "Next: $(node -e 'console.log(require("next/package.json").version)' 2>/dev/null || echo unknown)"
echo

echo "[2] CRUD ENGINE"
echo "--------------------------------------------------------------"

node <<'NODE'
const crud = require("./framework/api/crud-route");

console.log("typeof default export:", typeof crud);
console.log("exports:", Object.keys(crud));

for (const name of [
  "createCrudRoute",
  "crudRoute",
  "createCollectionHandlers"
]) {
  console.log(`${name}:`, typeof crud[name]);
}

if (typeof crud.createCrudRoute === "function") {
  const handlers = crud.createCrudRoute("administration");

  console.log("createCrudRoute() result type:", typeof handlers);
  console.log("handler keys:", Object.keys(handlers));

  for (const method of ["GET", "POST", "PATCH", "DELETE"]) {
    console.log(`${method}:`, typeof handlers[method]);
  }
}
NODE

echo
echo "[3] ADMINISTRATION BASE ROUTE"
echo "--------------------------------------------------------------"
sed -n '1,220p' app/api/administration/route.js

echo
echo "[4] ADMINISTRATION ID ROUTE"
echo "--------------------------------------------------------------"
sed -n '1,260p' 'app/api/administration/[id]/route.js'

echo
echo "[5] CUSTOMER BASE ROUTE"
echo "--------------------------------------------------------------"
sed -n '1,220p' app/api/customers/route.js

echo
echo "[6] CUSTOMER ID ROUTE"
echo "--------------------------------------------------------------"
sed -n '1,260p' 'app/api/customers/[id]/route.js'

echo
echo "[7] ROUTE EXPORT CONTRACT"
echo "--------------------------------------------------------------"

node <<'NODE'
const routes = [
  "app/api/administration/route.js",
  "app/api/administration/[id]/route.js",
  "app/api/customers/route.js",
  "app/api/customers/[id]/route.js"
];

for (const file of routes) {
  console.log();
  console.log("ROUTE:", file);

  try {
    const mod = require("./" + file);

    console.log("module keys:", Object.keys(mod));

    for (const name of [
      "GET",
      "POST",
      "PATCH",
      "DELETE",
      "PUT",
      "OPTIONS",
      "HEAD"
    ]) {
      if (name in mod) {
        console.log(`${name}:`, typeof mod[name]);
      }
    }

    console.log("default:", typeof mod.default);
  } catch (error) {
    console.error("LOAD FAILED");
    console.error(error.stack || error);
  }
}
NODE

echo
echo "[8] APPLICATION SERVICE"
echo "--------------------------------------------------------------"

node <<'NODE'
const service = require("./framework/application-service");

console.log("exports:", Object.keys(service));

for (const name of [
  "repository",
  "list",
  "get",
  "create",
  "update",
  "remove"
]) {
  console.log(`${name}:`, typeof service[name]);
}
NODE

echo
echo "[9] NEXT CONFIG"
echo "--------------------------------------------------------------"

if [ -f next.config.js ]; then
    sed -n '1,260p' next.config.js
else
    echo "No next.config.js"
fi

echo
echo "[10] PACKAGE"
echo "--------------------------------------------------------------"

node -e '
const p=require("./package.json");
console.log(JSON.stringify({
  type:p.type,
  scripts:p.scripts,
  dependencies:p.dependencies,
  devDependencies:p.devDependencies
},null,2))
'

echo
echo "[11] TYPESCRIPT / JS CONFIG"
echo "--------------------------------------------------------------"

[ -f jsconfig.json ] && cat jsconfig.json || true
[ -f tsconfig.json ] && cat tsconfig.json || true

echo
echo "=============================================================="
echo " DIAGNOSTIC COMPLETE"
echo "=============================================================="
echo
echo "Do NOT run npm run build yet."
echo
echo "The output above identifies the exact Next.js route/export"
echo "contract failure behind: TypeError: d is not a function"
echo
