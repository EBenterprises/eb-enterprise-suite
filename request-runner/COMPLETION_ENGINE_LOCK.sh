#!/data/data/com.termux/files/usr/bin/bash

ROOT="$HOME/request-runner"
LOCK="$ROOT/.completion-engine.lock"

acquire_lock() {
    if mkdir "$LOCK" 2>/dev/null; then
        echo "$$" > "$LOCK/pid"
        date +%s > "$LOCK/start"
        trap release_lock EXIT INT TERM
        return 0
    fi

    if [ -f "$LOCK/pid" ]; then
        OLD_PID="$(cat "$LOCK/pid" 2>/dev/null || true)"

        if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
            echo
            echo "COMPLETION ENGINE® already running: PID $OLD_PID"
            echo "Refusing duplicate execution."
            return 1
        fi
    fi

    rm -rf "$LOCK"
    mkdir "$LOCK" || return 1
    echo "$$" > "$LOCK/pid"
    date +%s > "$LOCK/start"

    trap release_lock EXIT INT TERM
    return 0
}

release_lock() {
    rm -rf "$LOCK" 2>/dev/null || true
}

acquire_lock
