#!/data/data/com.termux/files/usr/bin/bash

clear 2>/dev/null || true

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

CMD="${1:-check}"

case "$CMD" in
  check)
    ./scripts/check.sh
    ;;
  validate)
    node scripts/validate.mjs
    ;;
  build)
    npm run build
    STATUS=$?

    if [ "$STATUS" -eq 0 ]; then
      printf '\n[OK] GREEN - build passed\n'
    else
      printf '\n[ERR] RED - build failed\n'
    fi

    exit "$STATUS"
    ;;
  *)
    printf '[ERR] Unknown command: %s\n' "$CMD"
    printf '[INFO] Usage: %s [check|validate|build]\n' "$0"
    exit 1
    ;;
esac
