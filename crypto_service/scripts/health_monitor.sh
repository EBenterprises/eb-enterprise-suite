#!/usr/bin/env bash
while true; do
    if ! ./scripts/daemon.sh status | grep -q "running"; then
        echo "[$(date)] Service down! Triggering auto-recovery..."
        ./scripts/deploy.sh
    fi
    sleep 30
done
