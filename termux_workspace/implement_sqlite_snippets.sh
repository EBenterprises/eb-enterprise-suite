#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "[*] Implementing zero-dependency SQLite local store for snippet tagging..."

cat << 'PYDB' > snippet_store.py
#!/usr/bin/env python3
import sqlite3
import os
import sys
import json

DB_PATH = os.path.expanduser('~/termux_workspace/snippets.db')

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS snippets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            code TEXT NOT NULL,
            tag TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

def add_snippet(title, code, tag):
    init_db()
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO snippets (title, code, tag) VALUES (?, ?, ?)", (title, code, tag))
    conn.commit()
    conn.close()
    print(f"[+] Snippet '{title}' stored successfully with tag '{tag}'.")

def list_snippets(tag=None):
    init_db()
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    if tag:
        cursor.execute("SELECT id, title, tag, created_at FROM snippets WHERE tag = ?", (tag,))
    else:
        cursor.execute("SELECT id, title, tag, created_at FROM snippets")
    rows = cursor.fetchall()
    conn.close()
    
    print(json.dumps([{"id": r[0], "title": r[1], "tag": r[2], "created_at": r[3]} for r in rows], indent=2))

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 snippet_store.py [add|list] ...")
        sys.exit(1)
    
    cmd = sys.argv[1]
    if cmd == 'add' and len(sys.argv) == 5:
        add_snippet(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == 'list':
        tag = sys.argv[2] if len(sys.argv) > 2 else None
        list_snippets(tag)
    else:
        print("Invalid arguments.")
PYDB

chmod +x snippet_store.py
echo "[+] Created zero-dependency SQLite snippet manager (snippet_store.py)."

# Commit changes
git add .
if ! git diff --cached --quiet; then
    git commit -m "Milestone update: Added zero-dependency SQLite local store for snippet tagging $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== SQLite Snippet Tagging Integration Complete ==="
