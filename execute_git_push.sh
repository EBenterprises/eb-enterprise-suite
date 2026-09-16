#!/bin/bash

TOKEN="Ghp_UKkbfA6XQMVMAU1u4qkhHdiuS0cWsE1luoJc"

echo "🚀 Authenticating and pushing Request Runner ($r$) to GitHub..."

# Configure git credentials explicitly with the token
git remote set-url origin https://eastonbodeux:${TOKEN}@github.com/eastonbodeux/request-runner.git

# Push to origin main
git push -u origin main

echo "✅ Repository successfully pushed to GitHub for EB Enterprises!"
