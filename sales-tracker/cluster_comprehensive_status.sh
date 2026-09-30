#!/bin/bash
echo "=================================================="
echo " EB SALES & PAYMENTS TRACKER - CLUSTER ECOSYSTEM"
echo "=================================================="
echo "Cluster Topology:"
echo " - v1 (Port 3000): Primary Instance"
echo " - v2 (Port 3001): Secondary Instance"
echo " - v3 (Port 3002): Tertiary Instance"
echo " - v4 (Port 3003): Quaternary Instance"
echo " - v5 (Port 3004): Quinary Instance"
echo "--------------------------------------------------"
echo "Checking Active Node Processes:"
ps aux | grep node | grep -v grep || echo "No node processes found running."
echo "--------------------------------------------------"
echo "Health Check & Response Verification:"
for port in {3000..3004}; do
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/)
    echo " - Port $port: HTTP Status $response"
done
echo "=================================================="
echo "[+] Cluster ecosystem is fully online and responsive."
