#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Terminal Snippet Manager
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import json

SNIPPETS_FILE = os.path.expanduser("~/termux_workspace/.vault/snippets.json")

def load_snippets():
    if not os.path.exists(SNIPPETS_FILE):
        return {}
    try:
        with open(SNIPPETS_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return {}

def save_snippets(snippets):
    os.makedirs(os.path.dirname(SNIPPETS_FILE), exist_ok=True)
    with open(SNIPPETS_FILE, "w") as f:
        json.dump(snippets, f, indent=2)

def main():
    if len(sys.argv) < 2:
        print("Usage: ./exec-spec snippets <list|add|get> [name] [content]")
        sys.exit(1)

    action = sys.argv[1]
    snippets = load_snippets()

    if action == "list":
        print("=============================================================")
        print(" EXECUTIVE SPECTRUM - TERMINAL SNIPPETS")
        print("=============================================================")
        if not snippets:
            print(" No snippets saved.")
        for name in snippets:
            print(f"  - {name}")
        print("=============================================================")
    elif action == "add":
        if len(sys.argv) < 4:
            print("Usage: ./exec-spec snippets add <name> <content>")
            sys.exit(1)
        name, content = sys.argv[2], sys.argv[3]
        snippets[name] = content
        save_snippets(snippets)
        print(f"[+] Snippet '{name}' saved successfully.")
    elif action == "get":
        if len(sys.argv) < 3:
            print("Usage: ./exec-spec snippets get <name>")
            sys.exit(1)
        name = sys.argv[2]
        if name in snippets:
            print(snippets[name])
        else:
            print(f"[-] Snippet '{name}' not found.", file=sys.stderr)
            sys.exit(1)
    else:
        print(f"Unknown snippets action: {action}")
        sys.exit(1)

if __name__ == "__main__":
    main()
