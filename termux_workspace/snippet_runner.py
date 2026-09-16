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
