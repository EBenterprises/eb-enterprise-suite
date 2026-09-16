#!/bin/bash

TOKEN="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"

echo "🚀 Re-authenticating and pushing with correct token format..."

# Ensure token case matches GitHub requirements and configure credential helper / remote url properly
git remote set-url origin https://${TOKEN}@github.com/eastonbodeux/request-runner.git

# Push to origin main
git push -u origin main

echo "✅ Deployment push completed successfully!"
