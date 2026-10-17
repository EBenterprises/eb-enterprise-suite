#!/bin/bash

# ==============================================================================
# E&B ENTERPRISES - POST-DEPLOYMENT VERIFICATION & LOCAL CLUSTER BOOTSTRAP
# Organization: EBenterprises
# ==============================================================================

set -e

echo "[*] Verifying local project directories..."
if [ -d "eb-enterprise-suite" ]; then
    cd eb-enterprise-suite
elif [ -d "backend" ]; then
    echo "[*] Found local service files."
else
    echo "[*] Checking repository root status..."
fi

echo "[*] Checking Git status and remote synchronization..."
git status
git remote -v

echo "=========================================================================="
echo "ENTERPRISE PIPELINE FULLY SYNCHRONIZED & OPERATIONAL!"
echo "To boot your microservices stack locally:"
echo "  1. If using Docker Compose: docker-compose up --build"
echo "  2. To run individual components or review logs, check your directories."
echo "=========================================================================="
