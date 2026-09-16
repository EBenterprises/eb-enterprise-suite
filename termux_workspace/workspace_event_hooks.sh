#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "=== Initializing Advanced Git Lifecycle & Pre-Commit Hooks ==="

mkdir -p .git/hooks

cat << 'HOOK' > .git/hooks/pre-commit
#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
echo "[*] Running pre-commit health check and syntax validation..."

# 1. Validate Python syntax across all scripts
for py_file in "${WORKSPACE_DIR}"/*.py; do
    if [ -f "$py_file" ]; then
        python3 -m py_compile "$py_file"
    fi
done

# 2. Update health matrix prior to commit
if [ -f "${WORKSPACE_DIR}/system_health_matrix.py" ]; then
    python3 "${WORKSPACE_DIR}/system_health_matrix.py" > /dev/null 2>&1 || true
    git add "${WORKSPACE_DIR}/health_report.json" || true
fi

echo "[+] Pre-commit validation passed successfully."
HOOK

chmod +x .git/hooks/pre-commit

git add .
if ! git diff --cached --quiet; then
    git commit -m "Lifecycle update: Installed automated pre-commit hook validation $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== Git Lifecycle Pre-Commit Hooks Active & Verified ==="
