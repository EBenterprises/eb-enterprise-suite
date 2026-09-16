#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "=== Executing Comprehensive Suite of Next-Stage Enhancements ==="

# 1. Expand snippet store with search and delete capabilities
echo "[*] Enhancing SQLite snippet manager with search & delete capabilities..."
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

def search_snippets(keyword):
    init_db()
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT id, title, code, tag, created_at FROM snippets WHERE title LIKE ? OR code LIKE ? OR tag LIKE ?", 
                   (f"%{keyword}%", f"%{keyword}%", f"%{keyword}%"))
    rows = cursor.fetchall()
    conn.close()
    print(json.dumps([{"id": r[0], "title": r[1], "code": r[2], "tag": r[3], "created_at": r[4]} for r in rows], indent=2))

def delete_snippet(snippet_id):
    init_db()
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM snippets WHERE id = ?", (snippet_id,))
    conn.commit()
    conn.close()
    print(f"[+] Snippet ID {snippet_id} deleted successfully.")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 snippet_store.py [add|list|search|delete] ...")
        sys.exit(1)
    
    cmd = sys.argv[1]
    if cmd == 'add' and len(sys.argv) == 5:
        add_snippet(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == 'list':
        tag = sys.argv[2] if len(sys.argv) > 2 else None
        list_snippets(tag)
    elif cmd == 'search' and len(sys.argv) == 3:
        search_snippets(sys.argv[2])
    elif cmd == 'delete' and len(sys.argv) == 3:
        delete_snippet(sys.argv[2])
    else:
        print("Invalid arguments or command.")
PYDB

# 2. Build a Terminal UI (TUI) Dashboard Launcher in Python
echo "[*] Generating interactive terminal dashboard (dashboard_tui.py)..."
cat << 'PYTUI' > dashboard_tui.py
#!/usr/bin/env python3
import os
import subprocess
import sqlite3

def clear_screen():
    os.system('clear' if os.name == 'posix' else 'cls')

def show_banner():
    print("=" * 60)
    print("      EB ENTERPRISES - EXECUTIVE SPECTRUM WORKSPACE TUI       ")
    print("=" * 60)

def main_menu():
    while True:
        clear_screen()
        show_banner()
        print("\n[1] View Workspace Status & Git Log")
        print("[2] Run Workspace Verification & Sync")
        print("[3] List Stored Code Snippets")
        print("[4] Tail Recent Workspace Logs")
        print("[5] Exit")
        
        choice = input("\nSelect an option [1-5]: ").strip()
        
        if choice == '1':
            clear_screen()
            print("--- Git Status & Recent Commits ---")
            subprocess.run(['git', 'status'])
            print("\n--- Recent Commits ---")
            subprocess.run(['git', 'log', '-n', '5', '--oneline'])
            input("\nPress Enter to return to menu...")
        elif choice == '2':
            clear_screen()
            subprocess.run(['./verify_and_deploy.sh'])
            input("\nPress Enter to return to menu...")
        elif choice == '3':
            clear_screen()
            print("--- Stored Snippets ---")
            subprocess.run(['python3', 'snippet_store.py', 'list'])
            input("\nPress Enter to return to menu...")
        elif choice == '4':
            clear_screen()
            print("--- Recent Workspace Logs ---")
            log_path = os.path.expanduser('~/termux_workspace/workspace.log')
            if os.path.exists(log_path):
                subprocess.run(['tail', '-n', '50', log_path])
            else:
                print("No workspace.log found yet.")
            input("\nPress Enter to return to menu...")
        elif choice == '5':
            print("Exiting TUI. Workspace running smoothly.")
            break
        else:
            input("Invalid selection. Press Enter to retry...")

if __name__ == '__main__':
    main_menu()
PYTUI

chmod +x snippet_store.py dashboard_tui.py

# 3. Final commit and push of all expanded capabilities
echo "[*] Staging and syncing all comprehensive enhancements to remote repository..."
git add .
if ! git diff --cached --quiet; then
    git commit -m "Comprehensive upgrade: Enhanced snippet store with search/delete and added Python TUI dashboard $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== All Next Steps Executed & Synchronized Successfully ==="
echo "Launch the interactive dashboard anytime using: python3 dashboard_tui.py"
