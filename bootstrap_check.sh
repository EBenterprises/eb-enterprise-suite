#!/usr/bin/env bash
set -e

echo "=== Checking Environment ==="
echo "Node version: $(node -v 2>/dev/null || echo 'NOT FOUND')"
echo "npm version: $(npm -v 2>/dev/null || echo 'NOT FOUND')"
echo "Docker version: $(docker -v 2>/dev/null || echo 'NOT FOUND')"
echo "Git version: $(git --version 2>/dev/null || echo 'NOT FOUND')"

if [ ! -d "eb-enterprise-suite" ]; then
    echo "[-] Repository folder 'eb-enterprise-suite' not found in current directory."
    echo "[-] Cloning from GitHub..."
    git clone https://github.com/EBenterprises/eb-enterprise-suite.git
fi

cd eb-enterprise-suite

echo "=== Installing Dependencies & Starting Services ==="
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    echo "[+] Docker found. Launching via docker-compose..."
    if command -v docker-compose &> /dev/null; then
        docker-compose up --build -d
    else
        docker compose up --build -d
    fi
    echo "[+] Services started in background via Docker!"
else
    echo "[-] Docker not found. Setting up local Node processes..."
    
    # Install Gateway
    if [ -d "gateway" ]; then
        cd gateway && npm install && cd ..
    fi
    # Install Auth
    if [ -d "auth-service" ]; then
        cd auth-service && npm install && cd ..
    fi
    # Install Sales
    if [ -d "sales-service" ]; then
        cd sales-service && npm install && cd ..
    fi
    
    echo "[+] Node dependencies installed! Start services manually in separate tabs."
fi
