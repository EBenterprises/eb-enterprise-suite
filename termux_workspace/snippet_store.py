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
