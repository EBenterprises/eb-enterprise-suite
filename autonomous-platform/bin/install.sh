#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Installing Autonomous Platform Completion Engine®"

command -v node >/dev/null 2>&1 || {
    echo "ERROR: Node.js is required."
    exit 1
}

mkdir -p "$ROOT"/{state,logs,plans,worktrees,artifacts,checkpoints}

echo "✓ Runtime available"
echo "✓ Persistent state available"
echo "✓ Autonomous engine installed"
echo
echo "Launch with:"
echo
echo "node \"$ROOT/bin/platform.js\" \"YOUR COMPLETE PLATFORM REQUEST\""
