#!/bin/bash
# Sales Tracker - Multi-Version Data Finder & Git Tag Inspector

TARGET_DIR="$HOME/sales-tracker"

if [ ! -d "$TARGET_DIR" ]; then
    echo "[!] Directory $TARGET_DIR not found. Cloning repository..."
    git clone https://github.com/EBenterprises/sales-tracker.git "$TARGET_DIR"
fi

cd "$TARGET_DIR" || exit 1

echo "=========================================="
echo "   SALES TRACKER TRANSACTION FILE FINDER  "
echo "=========================================="
echo ""

echo "[1] Checking Git Branches & Remote Tags:"
git fetch --all --tags
git tag -l

echo ""
echo "[2] Locating all transactions.json instances:"
find . -type f -name "transactions.json"

echo ""
echo "[3] Active V5 Port Check & File Contents:"
if [ -f "$TARGET_DIR/v5/transactions.json" ]; then
    echo "Found V5 transactions.json:"
    cat "$TARGET_DIR/v5/transactions.json"
elif [ -f "$TARGET_DIR/transactions.json" ]; then
    echo "Found root transactions.json:"
    cat "$TARGET_DIR/transactions.json"
else
    echo "[!] Searching commit history for lost transactions.json..."
    git log --all --full-history -- "**/transactions.json" "transactions.json"
fi

