#!/usr/bin/env bash
set -euo pipefail

echo "=== Detailed Git Log with Timestamps ==="
git log --all --format="%h - %an, %ad : %s" --date=local -n 25
