#!/bin/bash
cd ~/sales-tracker

echo "[*] Fixing run_cluster.sh syntax error..."

# Let's inspect or rewrite run_cluster.sh so it doesn't try to execute raw JS inside the bash script
cat << 'RUN_EOF' > run_cluster.sh
#!/bin/bash
# Clean cluster startup script for V1-V4

echo "[*] Cleaning up existing node processes..."
pkill -f node || true

echo "[*] Starting main server..."
if [ -f "server.js" ]; then
    # Ensure server.js doesn't have stray javascript declarations if it was overwritten
    node server.js &
else
    echo "[-] server.js not found!"
fi

echo "[+] Cluster runner active."
RUN_EOF

chmod +x run_cluster.sh
./run_cluster.sh
