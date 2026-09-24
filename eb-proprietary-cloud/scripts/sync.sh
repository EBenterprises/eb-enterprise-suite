#!/bin/bash
set -e

REMOTE_HOST="${PROPRIETARY_HOST}"
REMOTE_USER="${PROPRIETARY_USER:-root}"

if [ -z "$REMOTE_HOST" ]; then
    echo "Error: PROPRIETARY_HOST environment variable is not set."
    exit 1
fi

echo "[*] Building proprietary container package locally..."
docker build -t proprietary-core:latest ./core

echo "[*] Exporting image archive..."
docker save proprietary-core:latest | gzip > /tmp/core.tar.gz

echo "[*] Transferring payload to proprietary node..."
scp /tmp/core.tar.gz ${REMOTE_USER}@${REMOTE_HOST}:/opt/proprietary-app/core.tar.gz

echo "[*] Executing live remote deployment sequence..."
ssh ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
    cd /opt/proprietary-app
    docker load -i core.tar.gz
    docker stop proprietary-app || true
    docker rm proprietary-app || true
    docker run -d \
        --name proprietary-app \
        --restart always \
        -p 80:8080 \
        -v /opt/proprietary-app/data:/opt/proprietary-app/data \
        proprietary-core:latest
    rm core.tar.gz
    echo "[+] Proprietary deployment live and active."
ENDSSH

rm /tmp/core.tar.gz
