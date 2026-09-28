#!/bin/bash
set -e

echo "[+] Cleaning stale git lock..."
rm -f ~/.git/index.lock

echo "[+] Verifying sales-tracker cluster status..."
cd ~/sales-tracker
./deploy_cluster.sh
