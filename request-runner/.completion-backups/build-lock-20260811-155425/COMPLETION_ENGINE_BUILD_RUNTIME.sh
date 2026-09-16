#!/data/data/com.termux/files/usr/bin/bash

# COMPLETION_ENGINE® — BUILD RUNTIME POLICY
# Android/ARM64 + Next.js 16 production policy.
#
# IMPORTANT:
# package.json owns the --webpack flag.
# The runtime MUST NOT inject another bundler flag.
# TURBOPACK environment variables are deliberately unset.

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
    echo "[BUILD] Bundler flag owner: package.json"

    npm run build
}

completion_engine_verify_build() {
    cd "$COMPLETION_ENGINE_ROOT" || return 1

    [ -d ".next" ] || return 1
    [ -d ".next/server" ] || return 1
    [ -f ".next/server/pages-manifest.json" ] || return 1

    return 0
}

completion_engine_build_and_verify() {
    completion_engine_build
    local build_status=$?

    if [ "$build_status" -ne 0 ]; then
        echo "[VERIFY] FAIL: build exit $build_status"
        return "$build_status"
    fi

    if completion_engine_verify_build; then
        echo "[VERIFY] PASS: production artifacts valid"
        return 0
    fi

    echo "[VERIFY] FAIL: production artifacts missing"
    return 1
}

export COMPLETION_ENGINE_BUILD_RUNTIME_LOADED=1
