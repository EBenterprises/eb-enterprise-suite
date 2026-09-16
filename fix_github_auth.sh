#!/bin/bash

USERNAME="ebenterprises"
TOKEN="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"

echo "🔧 Configuring git credentials for username: $USERNAME..."

# Configure Git global user settings
git config --global user.name "Easton Bodeux"
git config --global user.email "eastonbodeuxenterprises@gmail.com"

# Set remote URL using the exact GitHub username 'ebenterprises'
git remote set-url origin https://${USERNAME}:${TOKEN}@github.com/${USERNAME}/request-runner.git

# Unset conflicting credential helpers
git config --global --unset credential.helper || true

# Execute push
git push -u origin main

echo "✅ Push script completed."
