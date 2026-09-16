#!/data/data/com.termux/files/usr/bin/bash

# COMPLETION ENGINE® — BUILD RUNTIME POLICY

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1

POLICY="$ROOT/.completion-build-policy"

if [ -f "$POLICY" ]; then
    set -a
    . "$POLICY"
    set +a
fi

# Android/ARM64 verified production path.
if [ "${PLATFORM:-}" = "android" ] && [ "${ARCH:-}" = "arm64" ]; then
    export NEXT_BUILD_ENGINE="webpack"
    export NEXT_BUILD_COMMAND="next build --webpack"
    export TURBOPACK="disabled"
fi

# Absolute fallback for the current verified environment.
if [ "$(uname -s 2>/dev/null)" = "Linux" ] && \
   [ "$(uname -m 2>/dev/null)" = "aarch64" ]; then
    export NEXT_BUILD_ENGINE="webpack"
    export NEXT_BUILD_COMMAND="next build --webpack"
    export TURBOPACK="disabled"
fi

completion_engine_build() {
    echo "[BUILD] Engine: ${NEXT_BUILD_ENGINE:-webpack}"
    echo "[BUILD] Command: ${NEXT_BUILD_COMMAND:-next build --webpack}"

    rm -rf .next

    npm run build
}

completion_engine_verify_build() {
    local fail=0

    [ "${VERIFY_BUILD_EXIT:-true}" = "true" ] || return 0

    if [ ! -d ".next" ]; then
        echo "[VERIFY] FAIL: .next missing"
        fail=1
    fi

    if [ "${VERIFY_NEXT_SERVER:-true}" = "true" ] && \
       [ ! -d ".next/server" ]; then
        echo "[VERIFY] FAIL: .next/server missing"
        fail=1
    fi

    if [ "${VERIFY_PAGES_MANIFEST:-true}" = "true" ] && \
       [ ! -f ".next/server/pages-manifest.json" ]; then
        echo "[VERIFY] FAIL: pages-manifest.json missing"
        fail=1
    fi

    if [ "$fail" -eq 0 ]; then
        echo "[VERIFY] PASS: production artifacts valid"
        return 0
    fi

    return 1
}

completion_engine_build_and_verify() {
    local build_status

    set +e
    completion_engine_build
    build_status=$?
    set -e

    if [ "$build_status" -ne 0 ]; then
        echo "[VERIFY] FAIL: build exit $build_status"
        return "$build_status"
    fi

    completion_engine_verify_build
}
