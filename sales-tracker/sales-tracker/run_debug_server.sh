#!/bin/bash
set -e

pkill -f "node" 2>/dev/null || true
sleep 1

cd ~/sales-tracker/instances/v1
node server.js
