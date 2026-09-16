#!/usr/bin/env bash
set -e
echo "Starting deployment sequence for crypto_service..."
./scripts/daemon.sh stop || true
cargo build --release
./scripts/daemon.sh start
./scripts/test_api.sh
echo "Deployment sequence completed successfully."
