#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

case "${1:-status}" in

    inspect|doctor)
        exec ./ANCHOR_UPGRADE_V2.sh
        ;;

    repair|fix)
        exec ./ANCHOR_UPGRADE_V2.sh
        ;;

    release)
        exec ./REQUEST_RUNNER_RELEASE_GATE.sh
        ;;

    start)
        exec ./EB_PLATFORM.sh start
        ;;

    stop)
        exec ./EB_PLATFORM.sh stop
        ;;

    restart)
        ./EB_PLATFORM.sh stop || true
        sleep 1
        exec ./EB_PLATFORM.sh start
        ;;

    status)
        exec ./EB_PLATFORM.sh status
        ;;

    guardian)
        exec ./ANCHOR_GUARDIAN.sh
        ;;

    verify)
        ./ANCHOR_UPGRADE_V2.sh
        ;;

    *)
        echo "ANCHOR® CONTROL"
        echo
        echo "Usage:"
        echo "  ./ANCHOR.sh inspect"
        echo "  ./ANCHOR.sh repair"
        echo "  ./ANCHOR.sh verify"
        echo "  ./ANCHOR.sh release"
        echo "  ./ANCHOR.sh status"
        echo "  ./ANCHOR.sh start"
        echo "  ./ANCHOR.sh stop"
        echo "  ./ANCHOR.sh restart"
        echo "  ./ANCHOR.sh guardian"
        exit 2
        ;;
esac
