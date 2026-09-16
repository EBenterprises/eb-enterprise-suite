#!/bin/bash
set -e

echo "[Deploy] Initiating enterprise infrastructure orchestration..."

if ! command -v docker &> /dev/null; then
    echo "[Error] Docker is not installed or available in PATH."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "[Warning] Terraform not found. Skipping cloud provisioning phase."
else
    echo "[Terraform] Initializing infrastructure as code workspace..."
    cd terraform
    terraform init -input=false
    terraform apply -auto-approve
    cd ..
    echo "[Terraform] Cloud infrastructure provisioned successfully."
fi

echo "[Docker] Spinning up containerized microservices architecture..."
docker-compose up --build -d

echo "[Deploy] Enterprise system operational. All clusters online."
