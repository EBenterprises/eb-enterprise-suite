#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=============================================================="
echo " EB PLATFORM® — FINAL CRUD RESOLUTION + PRODUCTION BUILD"
echo "=============================================================="
echo

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/.finalize-backup-$STAMP"

echo "[1] SAFETY BACKUP"
echo "--------------------------------------------------------------"

mkdir -p "$BACKUP"

cp -a app "$BACKUP/app"
cp -a framework "$BACKUP/framework"
cp -p package.json "$BACKUP/package.json"

echo "✓ Backup: $BACKUP"
echo

echo "[2] VERIFY CRUD ENGINE EXISTS"
echo "--------------------------------------------------------------"

test -f framework/api/crud-route.js

echo "✓ framework/api/crud-route.js exists"

node --check framework/api/crud-route.js

echo "✓ CRUD engine syntax valid"
echo

echo "[3] VERIFY ACTUAL NODE MODULE RESOLUTION"
echo "--------------------------------------------------------------"

node <<'NODE'
const fs = require("fs");
const path = require("path");

const collections = [
    "administration",
    "customers",
    "drivers",
    "locations",
    "notifications",
    "operations",
    "orders",
    "payments",
    "requests",
    "scheduling"
];

for (const collection of collections) {
    const routes = [
        `app/api/${collection}/route.js`,
        `app/api/${collection}/[id]/route.js`
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
            throw new Error(
                `CRUD import not found in ${route}`
            );
        }

        const importPath = match[1];
        const resolved = require.resolve(
            path.resolve(path.dirname(route), importPath)
        );

        const expected = path.resolve(
            "framework/api/crud-route.js"
        );

        if (resolved !== expected) {
            throw new Error(
                `${route}\n` +
                `  import:   ${importPath}\n` +
                `  resolves: ${resolved}\n` +
                `  expected: ${expected}`
            );
        }

        console.log(`✓ ${route}`);
        console.log(`  ${importPath}`);
        console.log(`  → ${resolved}`);
    }
}

console.log();
console.log("✓ ALL CRUD ROUTES RESOLVE TO THE REAL CRUD ENGINE");
NODE

echo

echo "[4] LOAD EVERY CRUD ROUTE"
echo "--------------------------------------------------------------"

node <<'NODE'
const collections = [
    "administration",
    "customers",
    "drivers",
    "locations",
    "notifications",
    "operations",
    "orders",
    "payments",
    "requests",
    "scheduling"
];

for (const collection of collections) {
    const base = require(
        `./app/api/${collection}/route.js`
    );

    const id = require(
        `./app/api/${collection}/[id]/route.js`
    );

    for (const [name, route] of [
        ["base", base],
        ["id", id]
    ]) {
        for (const method of [
            "GET",
            "POST",
            "PATCH",
            "DELETE"
        ]) {
            if (typeof route[method] !== "function") {
                throw new Error(
                    `${collection}/${name}: missing ${method}`
                );
            }
        }
    }

    console.log(`✓ ${collection}`);
}

console.log();
console.log("✓ ALL CRUD ROUTE MODULES LOAD");
NODE

echo

echo "[5] VERIFY APPLICATION SERVICE"
echo "--------------------------------------------------------------"

node <<'NODE'
const service = require("./framework/application-service");

const required = [
    "repository",
    "list",
    "get",
    "create",
    "update",
    "remove"
];

for (const name of required) {
    if (typeof service[name] !== "function") {
        throw new Error(
            `Application service missing ${name}`
        );
    }

    console.log(`✓ service.${name}()`);
}

console.log("✓ APPLICATION SERVICE CONTRACT VALID");
NODE

echo

echo "[6] REAL CRUD PERSISTENCE ROUND-TRIP"
echo "--------------------------------------------------------------"

node <<'NODE'
const service = require("./framework/application-service");

const collection = "__production_crud_verification__";

(async () => {
    const repository = service.repository(collection);

    if (typeof repository.clear === "function") {
        await repository.clear();
    }

    const created = await service.create(collection, {
        type: "production-verification",
        value: "created",
        timestamp: new Date().toISOString()
    });

    if (!created || !created.id) {
        throw new Error("CREATE failed");
    }

    console.log("✓ CREATE");

    const loaded = await service.get(
        collection,
        created.id
    );

    if (!loaded) {
        throw new Error("READ failed");
    }

    console.log("✓ READ");

    const updated = await service.update(
        collection,
        created.id,
        {
            value: "updated"
        }
    );

    if (!updated || updated.value !== "updated") {
        throw new Error("UPDATE failed");
    }

    console.log("✓ UPDATE");

    const removed = await service.remove(
        collection,
        created.id
    );

    if (!removed) {
        throw new Error("DELETE failed");
    }

    console.log("✓ DELETE");

    const deleted = await service.get(
        collection,
        created.id
    );

    if (deleted) {
        throw new Error(
            "DELETE verification failed"
        );
    }

    console.log("✓ DELETE VERIFIED");

    if (typeof repository.clear === "function") {
        await repository.clear();
    }

    console.log();
    console.log("✓ DURABLE CRUD ROUND-TRIP PASSED");
})().catch(error => {
    console.error(error);
    process.exit(1);
});
NODE

echo

echo "[7] VERIFY JAVASCRIPT SYNTAX"
echo "--------------------------------------------------------------"

FAILED=0

while IFS= read -r -d '' file; do
    if ! node --check "$file" >/dev/null 2>&1; then
        echo "✗ Syntax error: $file"
        node --check "$file"
        FAILED=1
    fi
done < <(
    find app framework \
        -type f \
        -name '*.js' \
        -print0
)

if [ "$FAILED" -ne 0 ]; then
    echo
    echo "✗ JavaScript syntax verification failed"
    exit 1
fi

echo "✓ JavaScript syntax clean"
echo

echo "[8] VERIFY BUILD COMMAND"
echo "--------------------------------------------------------------"

npm pkg set scripts.build="next build --webpack"

BUILD_COMMAND="$(npm pkg get scripts.build | tr -d '"')"

echo "Build: $BUILD_COMMAND"

if [ "$BUILD_COMMAND" != "next build --webpack" ]; then
    echo "✗ Unexpected build command"
    exit 1
fi

echo "✓ Webpack build locked"
echo

echo "[9] CLEAN ONLY GENERATED BUILD ARTIFACT"
echo "--------------------------------------------------------------"

rm -rf .next

echo "✓ .next removed"
echo "✓ Source and persistence data preserved"
echo

echo "[10] PRODUCTION WEBPACK BUILD"
echo "--------------------------------------------------------------"

npm run build

echo

echo "[11] VERIFY PRODUCTION ARTIFACT"
echo "--------------------------------------------------------------"

if [ ! -d ".next" ]; then
    echo "✗ .next missing"
    exit 1
fi

if [ ! -f ".next/BUILD_ID" ]; then
    echo "✗ .next/BUILD_ID missing"
    exit 1
fi

BUILD_ID="$(cat .next/BUILD_ID)"

if [ -z "$BUILD_ID" ]; then
    echo "✗ BUILD_ID empty"
    exit 1
fi

echo "✓ .next exists"
echo "✓ BUILD_ID: $BUILD_ID"

echo

echo "=============================================================="
echo " EB PLATFORM® — PRODUCTION BUILD PASSED"
echo "=============================================================="
echo
echo "✓ Correct CRUD path resolution"
echo "✓ Real CRUD engine"
echo "✓ GET"
echo "✓ POST"
echo "✓ PATCH"
echo "✓ DELETE"
echo "✓ Application service"
echo "✓ Persistent CRUD round-trip"
echo "✓ JavaScript syntax"
echo "✓ Next.js 16 Webpack build"
echo "✓ Production artifact"
echo
echo "BACKUP:"
echo "  $BACKUP"
echo
echo "DO NOT START MULTIPLE SERVERS."
echo
echo "Next verification:"
echo "  production server"
echo "  /api/health"
echo "  /api/customers"
echo "  real HTTP CRUD round-trip"
echo
