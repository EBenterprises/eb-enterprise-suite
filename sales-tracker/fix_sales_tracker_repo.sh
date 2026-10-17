#!/usr/bin/env bash
set -e

PROJECT_DIR="$HOME/sales-tracker"
cd "$PROJECT_DIR"

echo "[1/4] Isolating sales-tracker repository..."
# Remove any inherited git linking from parent/home directory
rm -rf .git

echo "[2/4] Initializing clean Git repository..."
git init
git branch -M main

echo "[3/4] Pointing remote origin to EBenterprises/sales-tracker..."
git remote add origin https://github.com/EBenterprises/sales-tracker.git

echo "[4/4] Verifying new repository origin..."
git remote -v

