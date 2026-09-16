#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="${1:-my_project}"

echo "[*] Creating project directory structure for: $PROJECT_NAME"
mkdir -p "$PROJECT_NAME"/{src,assets,config,tests}

cd "$PROJECT_NAME"

echo "[*] Initializing Git repository safely..."
if [ ! -d ".git" ]; then
    git init
    echo "[*] Git repository initialized successfully."
else
    echo "[!] Git repository already exists here."
fi

echo "[*] Generating base template files..."

cat << 'INNER_EOF' > README.md
# $PROJECT_NAME
Initialized automatically via Termux automation script.
INNER_EOF

cat << 'INNER_EOF' > src/main.sh
#!/usr/bin/env bash
echo "Running main script..."
INNER_EOF

chmod +x src/main.sh

echo "[*] Project scaffolding complete in $(pwd)"
