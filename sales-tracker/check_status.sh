echo "[+] Checking running Node processes..."
ps aux | grep node

echo -e "\n[+] Checking port bindings..."
netstat -tuln 2>/dev/null || ss -tuln

echo -e "\n[+] Checking recent server logs..."
for v in v1 v2 v3 v4 v5; do
    echo "=== instances/$v/server.log ==="
    if [ -f "instances/$v/server.log" ]; then
        tail -n 5 "instances/$v/server.log"
    else
        echo "No log file found."
    fi
done
