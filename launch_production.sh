#!/usr/bin/env bash
set -e

echo "[SYSTEM] Initializing EggFinder® Edge Mesh & Live Gateway..."

# 1. Scale out cluster nodes & gateway
./scale_mesh.sh

# 2. Run verification benchmark
node benchmark.js

echo ""
echo "======================================================================"
echo "✨ EGG-FINDER® EXECUTIVE PLATFORM FULLY ONLINE & OPERATIONAL"
echo "======================================================================"
echo "  • Global Mesh Gateway  : http://localhost:3000"
echo "  • Command Dashboard    : http://localhost:3000/dashboard.html"
echo "  • Producer Provision   : http://localhost:3000/admin.html"
echo "  • Payment Support      : Apple Pay, Google Pay, Visa, Mastercard, Interac"
echo "======================================================================"
