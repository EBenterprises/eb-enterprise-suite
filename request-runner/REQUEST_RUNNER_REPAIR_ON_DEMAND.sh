#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/request-runner"
cd "$ROOT" || exit 1

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".mass-repair-backup-$STAMP"
LOG="MASS_REPAIR_LOG.txt"

mkdir -p "$BACKUP"

log() {
    printf '%s\n' "$*" | tee -a "$LOG"
}

fail() {
    log "✗ $*"
    log "REPAIR STOPPED — no further changes."
    exit 1
}

log "=== REQUEST RUNNER® — ON-DEMAND MASS REPAIR ==="
log "Timestamp: $STAMP"

log "[1] SNAPSHOT"
cp -a framework "$BACKUP/" 2>/dev/null || true
cp -a tests "$BACKUP/" 2>/dev/null || true
cp -a package.json "$BACKUP/" 2>/dev/null || true
log "✓ Snapshot: $BACKUP"

log "[2] AUTHORIZATION CONTRACT"

if [ ! -f framework/security/authorization.js ]; then
    fail "Live Authorization implementation missing"
fi

if grep -q '^module\.exports = Authorization;' framework/security/authorization.js &&
   grep -q '^class Authorization' framework/security/authorization.js; then
    log "✓ Live Authorization has constructor export"
else
    log "! Live Authorization export is inconsistent"

    SOURCE=""

    for candidate in \
        ".crud-alias-backup-"*/framework/security/authorization.js \
        ".crud-contract-backup-"*/framework/security/authorization.js \
        ".crud-repair-backup-"*/framework/security/authorization.js \
        ".final-crud-repair-"*/framework/security/authorization.js \
        ".finalize-backup-"*/framework/security/authorization.js \
        ".module-fix-backup-"*/framework/security/authorization.js \
        ".backups/"*/framework/security/authorization.js
    do
        if [ -f "$candidate" ] &&
           grep -q '^class Authorization' "$candidate" &&
           grep -q '^module\.exports = Authorization;' "$candidate"; then
            SOURCE="$candidate"
            break
        fi
    done

    [ -n "$SOURCE" ] || fail "No known-good Authorization implementation found"

    cp "$SOURCE" framework/security/authorization.js
    log "✓ Restored Authorization from: $SOURCE"
fi

log "[3] DIRECT AUTH TEST"

node <<'NODE'
const Authorization = require("./framework/security/authorization");

if (typeof Authorization !== "function") {
  console.error("Authorization export is not constructable");
  process.exit(1);
}

const auth = new Authorization();

auth.grant("operations", "request.manage");

if (!auth.allows("operations", "request.manage")) {
  console.error("Authorization grant/allows contract failed");
  process.exit(1);
}

console.log("✓ Authorization constructor"
);
console.log("✓ Authorization grant"
);
console.log("✓ Authorization allows"
);
NODE

[ "$?" -eq 0 ] || fail "Authorization contract test failed"

log "[4] FULL TEST SUITE"
npm run eb:test
[ "$?" -eq 0 ] || fail "Project test suite still failing"

log "[5] DOCTOR"
npm run eb:doctor
[ "$?" -eq 0 ] || fail "Doctor failed"

log "[6] STATUS"
npm run eb:status
[ "$?" -eq 0 ] || fail "Status failed"

log "[7] PRODUCTION BUILD"
npm run build
[ "$?" -eq 0 ] || fail "Production build failed"

log "[8] COMPLETE"
log "✓ Authorization repaired"
log "✓ Test suite passed"
log "✓ Doctor passed"
log "✓ Status passed"
log "✓ Production build passed"
log "Backup: $BACKUP"
log "Log: $LOG"

log "=== REQUEST RUNNER® — MASS REPAIR COMPLETE ==="
