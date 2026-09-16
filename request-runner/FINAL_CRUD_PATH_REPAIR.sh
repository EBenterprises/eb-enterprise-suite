#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=============================================================="
echo " EB PLATFORM® — FINAL CRUD PATH + HANDLER REPAIR"
echo "=============================================================="
echo

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/.final-crud-repair-$STAMP"

echo "[1] BACKUP"
echo "--------------------------------------------------------------"

mkdir -p "$BACKUP"

cp -a app "$BACKUP/app"
cp -a framework "$BACKUP/framework"
cp -p package.json "$BACKUP/package.json"

echo "✓ Backup: $BACKUP"
echo

echo "[2] REPAIR API ROUTE IMPORT PATHS"
echo "--------------------------------------------------------------"

# Collection routes:
# app/api/<collection>/route.js
# ../../../framework/... is correct.
#
# ID routes:
# app/api/<collection>/[id]/route.js
# ../../../../framework/... is correct.

find app/api \
    -type f \
    -name 'route.js' \
    -print0 |
while IFS= read -r -d '' file; do

    case "$file" in
        app/api/health/route.js)
            continue
            ;;
    esac

    if [[ "$file" == app/api/*/*/route.js ]]; then
        # Collection route
        sed -i \
            -E 's#\.\./\.\./\.\./\.\./framework/api/crud-route#../../../framework/api/crud-route#g' \
            "$file"

        sed -i \
            -E 's#\.\./\.\./\.\./framework/api/crud-route#../../../framework/api/crud-route#g' \
            "$file"

    elif [[ "$file" == app/api/*/*/\[id\]/route.js ]]; then
        # ID route
        sed -i \
            -E 's#\.\./\.\./\.\./\.\./\.\./framework/api/crud-route#../../../../framework/api/crud-route#g' \
            "$file"

        sed -i \
            -E 's#\.\./\.\./\.\./\.\./framework/api/crud-route#../../../../framework/api/crud-route#g' \
            "$file"
    fi

done

echo "✓ Route imports normalized"
echo

echo "[3] FORCE-CORRECT CRUD ROUTE IMPORTS"
echo "--------------------------------------------------------------"

# Explicitly repair every route so there is no ambiguity.

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

    FILE="app/api/$collection/route.js"

    if [ -f "$FILE" ]; then

        sed -i \
            -E 's#require\(["'\''][^"'\'']*framework/api/crud-route["'\'']\)#require("../../../framework/api/crud-route")#g' \
            "$FILE"

        echo "✓ $FILE"

    fi

    FILE="app/api/$collection/[id]/route.js"

    if [ -f "$FILE" ]; then

        sed -i \
            -E 's#require\(["'\''][^"'\'']*framework/api/crud-route["'\'']\)#require("../../../../framework/api/crud-route")#g' \
            "$FILE"

        echo "✓ $FILE"

    fi

done

echo

echo "[4] REPLACE CRUD ENGINE WITH CORRECT HANDLER CONTEXT"
echo "--------------------------------------------------------------"

mkdir -p framework/api

cat > framework/api/crud-route.js <<'JS'
"use strict";

const service = require("../application-service");

function json(data, status = 200) {
    return Response.json(data, {
        status,
        headers: {
            "Cache-Control": "no-store"
        }
    });
}

async function readBody(request) {
    try {
        return await request.json();
    } catch {
        return {};
    }
}

async function getId(context) {
    const params = context?.params;

    if (!params) {
        return null;
    }

    if (typeof params.then === "function") {
        const resolved = await params;
        return resolved?.id ?? null;
    }

    return params.id ?? null;
}

async function list(collection) {
    const repository = service.repository(collection);

    if (typeof repository.findAll === "function") {
        return await repository.findAll();
    }

    if (typeof service.list === "function") {
        return await service.list(collection);
    }

    return [];
}

async function create(collection, data) {
    return await service.create(collection, data);
}

async function get(collection, id) {
    return await service.get(collection, id);
}

async function update(collection, id, data) {
    return await service.update(collection, id, data);
}

async function remove(collection, id) {
    return await service.remove(collection, id);
}

function createCrudRoute(collection) {
    if (!collection || typeof collection !== "string") {
        throw new TypeError("CRUD collection must be a string");
    }

    const GET = async (request, context = {}) => {
        const id = await getId(context);

        if (id !== null && id !== undefined && id !== "") {
            const record = await get(collection, id);

            if (!record) {
                return json({
                    ok: false,
                    error: "Not found",
                    collection,
                    id
                }, 404);
            }

            return json({
                ok: true,
                data: record,
                record,
                collection
            });
        }

        const records = await list(collection);

        return json({
            ok: true,
            data: records,
            records,
            collection,
            count: Array.isArray(records) ? records.length : 0
        });
    };

    const POST = async (request, context = {}) => {
        const body = await readBody(request);

        const record = await create(collection, body);

        return json({
            ok: true,
            data: record,
            record,
            collection
        }, 201);
    };

    const PATCH = async (request, context = {}) => {
        const id = await getId(context);

        if (!id) {
            return json({
                ok: false,
                error: "Missing id",
                collection
            }, 400);
        }

        const body = await readBody(request);

        const record = await update(
            collection,
            id,
            body
        );

        if (!record) {
            return json({
                ok: false,
                error: "Not found",
                collection,
                id
            }, 404);
        }

        return json({
            ok: true,
            data: record,
            record,
            collection,
            id
        });
    };

    const DELETE = async (request, context = {}) => {
        const id = await getId(context);

        if (!id) {
            return json({
                ok: false,
                error: "Missing id",
                collection
            }, 400);
        }

        const removed = await remove(
            collection,
            id
        );

        if (!removed) {
            return json({
                ok: false,
                error: "Not found",
                collection,
                id
            }, 404);
        }

        return json({
            ok: true,
            data: removed,
            record: removed,
            collection,
            id
        });
    };

    return {
        GET,
        POST,
        PATCH,
        DELETE
    };
}

const crudRoute = createCrudRoute;

module.exports = createCrudRoute;
module.exports.createCrudRoute = createCrudRoute;
module.exports.crudRoute = crudRoute;
module.exports.createCollectionHandlers = createCrudRoute;
module.exports.json = json;
module.exports.readBody = readBody;
JS

echo "✓ CRUD engine repaired"
echo

echo "[5] VERIFY EXACT IMPORT TARGETS"
echo "--------------------------------------------------------------"

FAILED=0

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

    FILE="app/api/$collection/route.js"

    if [ -f "$FILE" ]; then
        EXPECTED="../../../framework/api/crud-route.js"

        if grep -Fq "$EXPECTED" "$FILE"; then
            echo "✓ $FILE"
        else
            echo "✗ $FILE"
            grep -n "crud-route" "$FILE" || true
            FAILED=1
        fi
    fi

    FILE="app/api/$collection/[id]/route.js"

    if [ -f "$FILE" ]; then
        EXPECTED="../../../../framework/api/crud-route.js"

        if grep -Fq "$EXPECTED" "$FILE"; then
            echo "✓ $FILE"
        else
            echo "✗ $FILE"
            grep -n "crud-route" "$FILE" || true
            FAILED=1
        fi
    fi

done

if [ "$FAILED" -ne 0 ]; then
    echo
    echo "✗ CRUD import verification failed"
    exit 1
fi

echo "✓ All CRUD imports point inside request-runner"
echo

echo "[6] VERIFY NODE MODULE RESOLUTION"
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

    require("./" + route);

    console.log("✓", route);
}

console.log("✓ All CRUD route modules load successfully");
NODE

echo

echo "[7] VERIFY CRUD ENGINE CONTRACT"
echo "--------------------------------------------------------------"

node - <<'NODE'
const crud = require("./framework/api/crud-route");

if (typeof crud !== "function") {
    throw new Error("CRUD export is not callable");
}

for (const name of [
    "createCrudRoute",
    "crudRoute",
    "createCollectionHandlers"
]) {
    if (typeof crud[name] !== "function") {
        throw new Error(`Missing CRUD export: ${name}`);
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
        throw new Error(`Missing ${method} handler`);
    }
}

console.log("✓ CRUD engine contract valid");
NODE

echo

echo "[8] JAVASCRIPT SYNTAX"
echo "--------------------------------------------------------------"

find app framework \
    -type f \
    -name '*.js' \
    -print0 |
while IFS= read -r -d '' file; do

    if ! node --check "$file" >/dev/null 2>&1; then
        echo "✗ Syntax error: $file"
        node --check "$file"
        exit 1
    fi

done

echo "✓ JavaScript syntax clean"
echo

echo "[9] CLEAN BUILD"
echo "--------------------------------------------------------------"

rm -rf .next

echo "✓ .next removed"
echo

echo "[10] PRODUCTION WEBPACK BUILD"
echo "--------------------------------------------------------------"

npm pkg set scripts.build="next build --webpack"

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

echo "✓ .next exists"
echo "✓ BUILD_ID:"
cat .next/BUILD_ID

echo

echo "=============================================================="
echo " EB PLATFORM® — CRUD + WEBPACK BUILD PASSED"
echo "=============================================================="
echo
echo "✓ Correct route resolution"
echo "✓ Real CRUD engine"
echo "✓ GET"
echo "✓ POST"
echo "✓ PATCH"
echo "✓ DELETE"
echo "✓ Application service"
echo "✓ JavaScript syntax"
echo "✓ Next.js Webpack production build"
echo
echo "DO NOT start another server yet."
echo
echo "The next verification should be the production server,"
echo "health endpoint, CRUD HTTP round-trip, and persistence."
echo

