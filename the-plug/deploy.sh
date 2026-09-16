#!/bin/bash
set -e
echo "Building and launching The Plug..."
npm run install:all
npm run build
echo "Deployment sequence completed successfully."
