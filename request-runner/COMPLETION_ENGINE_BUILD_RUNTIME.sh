#!/data/data/com.termux/files/usr/bin/bash

COMPLETION_ENGINE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export COMPLETION_ENGINE_ROOT
export COMPLETION_ENGINE_BUILD_ENGINE="webpack"
export COMPLETION_ENGINE_BUILD_COMMAND="npm run build"
export NEXT_BUILD_ENGINE="webpack"
export NEXT_BUILD_COMMAND="next build --webpack"

unset TURBOPACK
unset NEXT_TURBOPACK
unset NEXT_PRIVATE_TURBOPACK

completion_engine_build() {
    cd "$COMPLETION_ENGINE_ROOT" || return 1

    unset TURBOPACK
    unset NEXT_TURBOPACK
    unset NEXT_PRIVATE_TURBOPACK

    echo "[BUILD] Engine: webpack"
    echo "[BUILD] Command: npm run build"

    npm run build
}

completion_engine_verify_build() {
    cd "$COMPLETION_ENGINE_ROOT" || return 1

    [ -d ".next" ] || return 1
    [ -d ".next/server" ] || return 1
    [ -f ".next/server/pages-manifest.json" ] || return 1
}

completion_engine_build_and_verify() {
    completion_engine_build || return $?

    if completion_engine_verify_build; then
        echo "[VERIFY] PASS"
        return 0
    fi

    echo "[VERIFY] FAIL"
    return 1
}

export COMPLETION_ENGINE_BUILD_RUNTIME_LOADED=1
