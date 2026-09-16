#!/bin/bash

echo "⚙️ Configuring Git credentials and remote repository for EB Enterprises..."

# 1. Configure Git user identity
git config --global user.name "Easton Bodeux"
git config --global user.email "eastonbodeuxenterprises@gmail.com"

# 2. Add remote repository if not already set
if ! git remote get-url origin > /dev/null 2>&1; then
  git remote add origin https://github.com/eastonbodeux/request-runner.git
  echo "Added GitHub remote origin."
else
  echo "Remote origin already configured."
fi

# 3. Final commit and push check
git branch -M main
git add .
git commit -m "chore: configure EB Enterprises identity and finalize build structure" || echo "No changes to commit."

echo "✅ Git configuration complete for EB Enterprises (eastonbodeuxenterprises@gmail.com)."
echo "To push your repository live, run: git push -u origin main"
