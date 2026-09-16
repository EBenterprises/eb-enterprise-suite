#!/bin/bash
set -e

echo "Verifying remote configuration..."
git remote -v

echo "Pushing stabilized workspace to main branch..."
git push origin main || git push -u origin main

echo "Deployment sync complete."
