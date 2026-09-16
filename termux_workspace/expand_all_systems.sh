#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "=== Expanding Workspace Ecosystem: Advanced Snippet Execution & Archival ==="

# 1. Create Snippet Execution Engine
cat << 'PYEXEC' > snippet_runner.py
#!/usr/bin/env python3
import sqlite3
import os
import sys
import subprocess
import tempfile

DB_PATH = os.path.expanduser('~/termux_workspace/snippets.db')

def run_snippet(snippet_id):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT title, code, tag FROM snippets WHERE id = ?", (snippet_id,))
    row = cursor.fetchone()
    conn.close()
    
    if not row:
        print(f"[-] Snippet ID {snippet_id} not found.")
        return

    title, code, tag = row
    print(f"[*] Executing Snippet [{snippet_id}]: {title} (Tag: {tag})")
    print("-" * 50)
    
    ext = ".sh"
    interpreter = "bash"
    if tag.lower() == 'python' or 'import ' in code or 'print(' in code:
        ext = ".py"
        interpreter = "python3"

    with tempfile.NamedTemporaryFile(mode='w', suffix=ext, delete=False) as f:
        f.write(code)
        tmp_name = f.name

    try:
        subprocess.run([interpreter, tmp_name], check=True)
    except Exception as e:
        print(f"[-] Execution error: {e}")
    finally:
        os.unlink(tmp_name)
    print("-" * 50)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 snippet_runner.py <snippet_id>")
        sys.exit(1)
    run_snippet(sys.argv[1])
PYEXEC

chmod +x snippet_runner.py

# 2. Create Automated Workspace Archiver
cat << 'PYSYNC' > workspace_archive.sh
#!/usr/bin/env bash
set -euo pipefail
ARCHIVE_DIR="${HOME}/termux_workspace/archives"
mkdir -p "$ARCHIVE_DIR"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
ARCHIVE_NAME="${ARCHIVE_DIR}/workspace_backup_${TIMESTAMP}.tar.gz"

echo "[*] Creating compressed workspace archive..."
tar --exclude="archives" --exclude=".git" -czf "$ARCHIVE_NAME" -C "${HOME}" termux_workspace
echo "[+] Archive successfully created at: $ARCHIVE_NAME"
PYSYNC

chmod +x workspace_archive.sh

# Commit all expansions
git add .
if ! git diff --cached --quiet; then
    git commit -m "Ecosystem expansion: Added snippet execution engine and automated archiver $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== Workspace Expansion Complete ==="
echo "1. Run snippets by ID: python3 snippet_runner.py <ID>"
echo "2. Create backup archive: ./workspace_archive.sh"
