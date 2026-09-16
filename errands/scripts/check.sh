#!/data/data/com.termux/files/usr/bin/bash

clear 2>/dev/null || true

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

FAIL=0

ok() {
  printf '[OK]  %s\n' "$1"
}

err() {
  printf '[ERR] %s\n' "$1"
  FAIL=$((FAIL + 1))
}

printf 'ERRANDS(R) CHECK\n\n'

FILES=(
"package.json"
"next.config.js"
"jsconfig.json"
"apps/web/app/layout.js"
"apps/web/app/page.js"
"apps/web/app/globals.css"
"apps/web/components/Brand.js"
"apps/web/components/Nav.js"
"apps/web/app/dashboard/page.js"
"apps/web/app/errands/new/page.js"
"apps/web/app/api/health/route.js"
"apps/web/app/api/errands/route.js"
"domain/errands/index.js"
"domain/locations/index.js"
"domain/users/index.js"
"domain/runners/index.js"
"domain/requests/index.js"
"services/requests/index.js"
"services/matching/index.js"
"services/dispatch/index.js"
"services/tracking/index.js"
"services/pricing/index.js"
"services/addressless-coordination/index.js"
"security/authentication/index.js"
"security/authorization/index.js"
"security/audit/index.js"
"events/registry/index.js"
"events/publishers/index.js"
"api/openapi/openapi.json"
"database/schema/README.md"
"database/migrations/0001_foundation.sql"
"README.md"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    ok "$file"
  else
    err "$file"
  fi
done

printf '\n'

if node -e "JSON.parse(require('fs').readFileSync('package.json','utf8'))" >/dev/null 2>&1; then
  ok "package.json syntax"
else
  err "package.json syntax"
fi

printf '\n'

if [ "$FAIL" -eq 0 ]; then
  printf '[OK] GREEN - 0 failures\n'
  exit 0
fi

printf '[ERR] RED - %s failures\n' "$FAIL"
exit 1
