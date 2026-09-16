#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
export OPENSSL_NO_VENDOR=1
echo "Building dynamically..."
cargo build --verbose
