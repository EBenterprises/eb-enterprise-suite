#!/bin/bash
cd ~/sales-tracker
echo "=== Last 20 lines of server.log ==="
tail -n 20 server.log || echo "No server.log found"
echo "=== Checking Node processes ==="
ps aux | grep node
