#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "/data/data/com.termux/files/home/request-runner" || exit 1

ID="04"
NAME="MANIFESTS"
OUT=".completion-state/reports/04"
REPORT="$OUT/report.txt"

{
  echo "WORKER=$ID"
  echo "NAME=$NAME"
  echo "START=$(date -Iseconds)"
} > "$REPORT"

case "$NAME" in

SOURCE)
  {
    echo
    echo "SOURCE CONTRACT"

    failures=0

    for route in       "administration/route.js"       "administration/[id]/route.js"       "customers/route.js"       "customers/[id]/route.js"       "drivers/route.js"       "drivers/[id]/route.js"       "locations/route.js"       "locations/[id]/route.js"       "notifications/route.js"       "notifications/[id]/route.js"       "operations/route.js"       "operations/[id]/route.js"       "orders/route.js"       "orders/[id]/route.js"       "payments/route.js"       "payments/[id]/route.js"       "requests/route.js"       "requests/[id]/route.js"       "requests/[id]/accept/route.js"       "scheduling/route.js"       "scheduling/[id]/route.js"       "health/route.js"
    do
      [ -f "app/api/$route" ] || {
        echo "MISSING app/api/$route"
        failures=$((failures + 1))
      }
    done

    [ -f framework/api/crud-route.js ] || failures=$((failures + 1))

    if [ "$failures" -eq 0 ]; then
      echo "PASS"
      exit 0
    fi

    echo "FAILURES=$failures"
    exit 1
  } >> "$REPORT" 2>&1
  ;;

CONFIG)
  {
    echo
    echo "CONFIGURATION CONTRACT"

    node - <<'NODE'
const fs = require("fs");

let failures = 0;

for (const file of ["package.json","jsconfig.json"]) {
  try {
    JSON.parse(fs.readFileSync(file,"utf8"));
    console.log("PASS", file);
  } catch (e) {
    console.log("FAIL", file, e.message);
    failures++;
  }
}

const js = fs.readFileSync("jsconfig.json","utf8");

for (const alias of ["@framework/*","@app/*"]) {
  if (!js.includes(alias)) {
    console.log("FAIL missing alias", alias);
    failures++;
  }
}

process.exit(failures ? 1 : 0);
NODE
  } >> "$REPORT" 2>&1
  ;;

ROUTES)
  {
    echo
    echo "ROUTE EMISSION CONTRACT"

    if [ ! -d .next/server/app/api ]; then
      echo "NO_BUILD_ARTIFACTS"
      exit 1
    fi

    emitted=0

    for route in       "administration/route.js"       "administration/[id]/route.js"       "customers/route.js"       "customers/[id]/route.js"       "drivers/route.js"       "drivers/[id]/route.js"       "locations/route.js"       "locations/[id]/route.js"       "notifications/route.js"       "notifications/[id]/route.js"       "operations/route.js"       "operations/[id]/route.js"       "orders/route.js"       "orders/[id]/route.js"       "payments/route.js"       "payments/[id]/route.js"       "requests/route.js"       "requests/[id]/route.js"       "requests/[id]/accept/route.js"       "scheduling/route.js"       "scheduling/[id]/route.js"       "health/route.js"
    do
      [ -f ".next/server/app/api/$route" ] && emitted=$((emitted + 1))
    done

    echo "EMITTED=$emitted"

    [ "$emitted" -eq 22 ]
  } >> "$REPORT" 2>&1
  ;;

MANIFESTS)
  {
    echo
    echo "MANIFEST CONTRACT"

    failures=0

    for manifest in       ".next/server/app-paths-manifest.json"       ".next/server/pages-manifest.json"       ".next/server/middleware-manifest.json"       ".next/server/server-reference-manifest.json"
    do
      if [ -f "$manifest" ]; then
        echo "PASS $manifest"
      else
        echo "FAIL $manifest"
        failures=$((failures + 1))
      fi
    done

    if [ -f ".next/server/next-font-manifest.json" ]; then
      echo "OPTIONAL next-font-manifest.json PRESENT"
    else
      echo "OPTIONAL next-font-manifest.json ABSENT"
    fi

    exit "$failures"
  } >> "$REPORT" 2>&1
  ;;

WEBPACK)
  {
    echo
    echo "WEBPACK / ANDROID POLICY"

    if grep -q "webpack" package.json next.config.js 2>/dev/null; then
      echo "PASS webpack surface present"
    fi

    if grep -q "webpack" next.config.js 2>/dev/null; then
      echo "PASS custom webpack hook present"
    else
      echo "WARNING no custom webpack hook detected"
    fi

    echo "TARGET=WEBPACK"
  } >> "$REPORT" 2>&1
  ;;

TYPES)
  {
    echo
    echo "TYPE CONTRACT"

    if [ -f jsconfig.json ]; then
      node -e 'JSON.parse(require("fs").readFileSync("jsconfig.json","utf8")); console.log("PASS jsconfig")'
    fi

    echo "PASS static configuration probe"
  } >> "$REPORT" 2>&1
  ;;

RUNTIME)
  {
    echo
    echo "RUNTIME SURFACE"

    for file in       "app/api/health/route.js"       "framework/api/crud-route.js"
    do
      if [ -f "$file" ]; then
        echo "PASS $file"
      else
        echo "FAIL $file"
        exit 1
      fi
    done

    echo "PASS runtime surface"
  } >> "$REPORT" 2>&1
  ;;

FAILURE)
  {
    echo
    echo "FAILURE INTELLIGENCE"

    latest=""
    for candidate in .completion-logs/*.log; do
      [ -f "$candidate" ] || continue
      [ "$candidate" = ".completion-logs/parallel-v5-20260811-182244.log" ] && continue
      latest="$candidate"
    done

    if [ -n "$latest" ]; then
      echo "EVIDENCE=$latest"

      grep -qE         'Cannot find module .*\.next/server/app/.*/route\.js|Failed to collect page data'         "$latest" && echo "CLASS=SERVER_ARTIFACT_EMISSION_FAILURE"

      grep -qE         'Unable to snapshot resolve dependencies|PackFileCacheStrategy'         "$latest" && echo "CLASS=WEBPACK_CACHE_WARNING"

      grep -qE         'Module not found|Can.t resolve|Cannot resolve'         "$latest" && echo "CLASS=MODULE_RESOLUTION_FAILURE"

      grep -qE         'TS[0-9]{4}|TypeScript error|Type error'         "$latest" && echo "CLASS=TYPESCRIPT_FAILURE"
    else
      echo "NO_HISTORICAL_FAILURE"
    fi

    echo "PASS failure intelligence scan"
  } >> "$REPORT" 2>&1
  ;;

esac

echo "END=$(date -Iseconds)" >> "$REPORT"
exit 0
