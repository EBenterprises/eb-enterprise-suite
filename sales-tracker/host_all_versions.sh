#!/bin/bash
set -e

echo "[+] Configuring and launching local host connections for versions v1 through v5..."

# Launch each version on its dedicated port
for ver in v1 v2 v3 v4 v5; do
    case $ver in
        v1) port=3001 ;;
        v2) port=3002 ;;
        v3) port=3003 ;;
        v4) port=3004 ;;
        v5) port=3005 ;;
    esac

    dir="releases/$ver"
    
    if [ ! -d "$dir" ]; then
        echo "[!] Directory $dir does not exist. Skipping."
        continue
    fi

    echo "[+] Launching $ver on http://localhost:$port..."
    
    # Kill any existing process on this version if running
    pkill -f "node.*releases/$ver/server.js" || true
    
    # Run in background with assigned PORT
    cd "$dir"
    PORT=$port nohup node server.js > server.log 2>&1 &
    cd - > /dev/null
    
    echo "[+] $ver running live on http://localhost:$port"
done

echo "--------------------------------------------------------"
echo " All Version Hosts Active:"
echo "   v1: http://localhost:3001"
echo "   v2: http://localhost:3002"
echo "   v3: http://localhost:3003"
echo "   v4: http://localhost:3004"
echo "   v5: http://localhost:3005"
echo "--------------------------------------------------------"
