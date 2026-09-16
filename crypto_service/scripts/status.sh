#!/usr/bin/env bash
echo "=== System Status ==="
./scripts/daemon.sh status
echo ""
echo "=== Last Log Entries ==="
tail -n 10 crypto_service.log
echo ""
echo "=== Endpoint Verification ==="
./scripts/test_api.sh
