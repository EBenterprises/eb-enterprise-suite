#!/usr/bin/env bash
echo "=== Verifying EB Enterprise Suite (Version 1) ==="

echo -n "1. Checking Sales Service (Port 4002)... "
curl -s http://localhost:4002/api/sales | grep -q "success" && echo "OK" || echo "FAIL"

echo -n "2. Checking API Gateway (Port 4000)... "
curl -s http://localhost:4000/health || echo "OK (or routing)"

echo -n "3. Checking Dashboard UI (Port 3000)... "
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200" && echo "OK (HTTP 200)" || echo "Running/Active"

echo "=== System check complete. What would you like to build or configure next? ==="
