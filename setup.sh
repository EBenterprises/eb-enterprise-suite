#!/bin/bash
set -e

echo "Creating directory structure..."
mkdir -p auth-system/backend/models
mkdir -p auth-system/backend/routes
mkdir -p auth-system/backend/middleware
mkdir -p auth-system/frontend/public
mkdir -p auth-system/frontend/src/components
mkdir -p auth-system/frontend/src/pages

echo "Directories created successfully."
