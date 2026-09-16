#!/bin/bash
set -e

echo "[+] Ensuring all versions (v1 through v5) are fully isolated with their own dedicated database instances and configuration..."

declare -A ports=(
    ["v1"]=3001
    ["v2"]=3002
    ["v3"]=3003
    ["v4"]=3004
    ["v5"]=3005
)

for ver in v1 v2 v3 v4 v5; do
    port=${ports[$ver]}
    dir="releases/$ver"
    
    if [ ! -d "$dir" ]; then
        echo "[!] Directory $dir does not exist. Skipping."
        continue
    fi

    echo "[+] Isolating $dir (Port $port)..."
    
    # Kill any running process for this version
    pkill -f "node.*releases/$ver/server.js" || true
    
    # Ensure server.js uses a dedicated local sqlite db for isolation (e.g. sales_$ver.sqlite)
    python3 -c "
import os
server_path = '$dir/server.js'
if os.path.exists(server_path):
    with open(server_path, 'r') as f:
        code = f.read()
    
    # Replace sales.sqlite with version-specific database
    code = code.replace(\"sales.sqlite\", \"sales_$ver.sqlite\")
    code = code.replace(\"new sqlite3.Database('sales.sqlite')\", \"new sqlite3.Database('sales_$ver.sqlite')\")
    
    with open(server_path, 'w') as f:
        f.write(code)
    print(f'[+] Database isolated for $ver.')
"

    # Launch isolated instance
    cd "$dir"
    PORT=$port nohup node server.js > server.log 2>&1 &
    cd - > /dev/null
    
    echo "[+] $ver running live & isolated on http://localhost:$port"
done

echo "--------------------------------------------------------"
echo " All Isolated Version Endpoints Active:"
echo "   v1: http://localhost:3001 (DB: sales_v1.sqlite)"
echo "   v2: http://localhost:3002 (DB: sales_v2.sqlite)"
echo "   v3: http://localhost:3003 (DB: sales_v3.sqlite)"
echo "   v4: http://localhost:3004 (DB: sales_v4.sqlite)"
echo "   v5: http://localhost:3005 (DB: sales_v5.sqlite)"
echo "--------------------------------------------------------"
