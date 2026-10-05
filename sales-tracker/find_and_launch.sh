#!/usr/bin/env bash
set -euo pipefail

echo "=== Searching common locations for sales-tracker ==="
TARGET_DIR=""

for path in "$HOME/sales-tracker" "$HOME/projects/sales-tracker" "$(pwd)/sales-tracker" "$(pwd)"; do
    if [ -d "$path" ] && ( [ -d "$path/v1" ] || [ -d "$path/instances" ] || [ -d "$path/releases" ] ); then
        TARGET_DIR="$path"
        break
    fi
done

if [ -z "$TARGET_DIR" ]; then
    echo "Searching entire home directory for sales-tracker..."
    TARGET_DIR=$(find ~ -type d -name "sales-tracker" 2>/dev/null | head -n 1)
fi

if [ -n "$TARGET_DIR" ] && [ -d "$TARGET_DIR" ]; then
    echo "Found sales-tracker at: $TARGET_DIR"
    cd "$TARGET_DIR"
    
    echo "=== Current Repository Status ==="
    git status
    
    echo "=== Searching for orchestrator or startup scripts ==="
    find . -maxdepth 2 -name "*.sh"
    
    if [ -f "./cluster_orchestrator.sh" ]; then
        echo "Executing existing cluster_orchestrator.sh..."
        ./cluster_orchestrator.sh
    elif [ -f "./start.sh" ]; then
        echo "Executing existing start.sh..."
        ./start.sh
    else
        echo "Launching v1 through v4 manually from existing directories..."
        # Launch v1-v4 if their respective directories exist
        for v in v1 v2 v3 v4; do
            if [ -d "$v" ] && [ -f "$v/server.js" ]; then
                echo "Starting $v..."
                cd "$v" && node server.js &
                cd ..
            elif [ -d "instances/$v" ] && [ -f "instances/$v/server.js" ]; then
                echo "Starting instances/$v..."
                cd "instances/$v" && node server.js &
                cd ../..
            fi
        done
    fi
else
    echo "Could not automatically locate the sales-tracker folder. Please let me know your current working path!"
fi
