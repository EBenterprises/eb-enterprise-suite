#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$(dirname "$0")" || exit 1

PASS=0
FAIL=0

ok() {
    echo "✓ $1"
    PASS=$((PASS+1))
}

bad() {
    echo "✗ $1"
    FAIL=$((FAIL+1))
}

echo "=============================================================="
echo " REQUEST RUNNER® — QUEUE → DISPATCH® ORCHESTRATION REPAIR"
echo " ADDITIVE / PRESERVE GREEN BASELINE"
echo "=============================================================="

echo
echo "[1] PRODUCTION BASELINE"
echo "--------------------------------------------------------------"

if ./FINAL_PRODUCTION_SNAPSHOT.sh >/dev/null 2>&1; then
    ok "Production baseline remains GREEN"
else
    bad "Production baseline failed"
    exit 1
fi

echo
echo "[2] BACKUPS"
echo "--------------------------------------------------------------"

STAMP="$(date +%Y%m%d-%H%M%S)"

cp -p apps/request-runner/index.js \
    "apps/request-runner/.index.js.orchestration-backup-$STAMP"

cp -p apps/request-runner/dispatch.js \
    "apps/request-runner/.dispatch.js.orchestration-backup-$STAMP"

ok "Application backups created"

echo
echo "[3] APPLICATION DISPATCH® EXPORT"
echo "--------------------------------------------------------------"

node - <<'NODE'
const fs = require("fs");

const file = "apps/request-runner/index.js";
let source = fs.readFileSync(file, "utf8");

const exportLine =
    'module.exports.dispatch = require("./dispatch");';

if (!source.includes(exportLine)) {
    source += `\n${exportLine}\n`;
    fs.writeFileSync(file, source);
    console.log("✓ app.dispatch export added");
} else {
    console.log("✓ app.dispatch export already present");
}
NODE

echo
echo "[4] DISPATCH® ASSIGNMENT SURFACE"
echo "--------------------------------------------------------------"

node - <<'NODE'
const fs = require("fs");

const file = "apps/request-runner/dispatch.js";
let source = fs.readFileSync(file, "utf8");

const marker = "module.exports.assign = function assign";

if (source.includes(marker)) {
    console.log("✓ Dispatch® assignment operation already present");
    process.exit(0);
}

const addition = `

/*
 * Dispatch® assignment operation.
 * Coordinates an isolated Request® with a Runner®.
 */
module.exports.assign = function assign(input, runnerIdArg) {
    const app = require("./index");

    const queue = app.requestQueue || app.queue || app.requestsQueue;
    const runners = app.runners;
    const state = app.dispatchState;

    let requestId;
    let runnerId;

    if (input && typeof input === "object") {
        requestId =
            input.requestId ||
            input.id ||
            (input.request && (input.request.id || input.request.requestId));

        runnerId =
            input.runnerId ||
            (input.runner && input.runner.id);
    } else {
        requestId = input;
        runnerId = runnerIdArg;
    }

    if (!requestId) {
        throw new Error("Dispatch® requires a Request® identifier");
    }

    if (!runnerId) {
        throw new Error("Dispatch® requires a Runner® identifier");
    }

    if (!runners || typeof runners.get !== "function") {
        throw new Error("Runner® registry unavailable");
    }

    const runner = runners.get(runnerId);

    if (!runner) {
        throw new Error("Runner® not found");
    }

    if (runner.status !== "available") {
        throw new Error("Runner® is not available");
    }

    if (typeof runners.setUnavailable === "function") {
        runners.setUnavailable(runnerId, requestId);
    } else if (typeof runners.setBusy === "function") {
        runners.setBusy(runnerId, requestId);
    } else {
        throw new Error("Runner® assignment operation unavailable");
    }

    if (state && typeof state.create === "function") {
        try {
            state.create({
                id: requestId,
                requestId,
                runnerId,
                status: "assigned"
            });
        } catch (_) {
            /* Existing state may already represent this assignment. */
        }
    }

    if (queue && typeof queue.remove === "function") {
        try {
            queue.remove(requestId);
        } catch (_) {
            /* Queue removal is best-effort for isolated orchestration. */
        }
    }

    return {
        requestId,
        runnerId,
        status: "assigned"
    };
};
`;

source += addition;
fs.writeFileSync(file, source);

console.log("✓ Dispatch® assignment operation added");
NODE

echo
echo "[5] SYNTAX"
echo "--------------------------------------------------------------"

if node --check apps/request-runner/index.js >/dev/null 2>&1; then
    ok "Application index syntax valid"
else
    bad "Application index syntax invalid"
fi

if node --check apps/request-runner/dispatch.js >/dev/null 2>&1; then
    ok "Dispatch® syntax valid"
else
    bad "Dispatch® syntax invalid"
fi

echo
echo "[6] APPLICATION SURFACE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app.runners) throw new Error("Runner® surface missing");
if (!app.dispatch) throw new Error("Dispatch® surface missing");
if (!app.requestQueue && !app.queue && !app.requestsQueue) {
    throw new Error("Request Queue® surface missing");
}

const dispatch = app.dispatch;

if (
    typeof dispatch.assign !== "function" &&
    typeof dispatch.dispatch !== "function" &&
    typeof dispatch.assignNext !== "function" &&
    typeof dispatch.next !== "function"
) {
    throw new Error("Dispatch® assignment operation missing");
}

console.log("✓ Queue® + Dispatch® + Runner® surfaces loaded");
NODE
then
    ok "Orchestration surface available"
else
    bad "Orchestration surface unavailable"
fi

echo
echo "[7] PRODUCTION BASELINE RECHECK"
echo "--------------------------------------------------------------"

if ./FINAL_PRODUCTION_SNAPSHOT.sh >/dev/null 2>&1; then
    ok "Production baseline remains GREEN"
else
    bad "Production baseline changed"
fi

echo
echo "=============================================================="
echo " QUEUE → DISPATCH® ORCHESTRATION REPAIR RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "ORCHESTRATION SURFACE REPAIRED"
    echo "READY FOR VERIFICATION"
else
    echo "STATUS: RED"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo "=============================================================="
