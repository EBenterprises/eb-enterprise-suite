#!/usr/bin/env python3
import os

GITIGNORE_PATH = os.path.expanduser("~/termux_workspace/.gitignore")

IGNORE_ENTRIES = [
    "__pycache__/",
    "*.pyc",
    "diagnostic_report.json",
    "telemetry_stream.jsonl"
]

def update_gitignore():
    existing = set()
    if os.path.exists(GITIGNORE_PATH):
        with open(GITIGNORE_PATH, "r") as f:
            existing = set(line.strip() for line in f if line.strip())

    added = False
    with open(GITIGNORE_PATH, "a") as f:
        for entry in IGNORE_ENTRIES:
            if entry not in existing:
                f.write(entry + "\n")
                added = True

    if added:
        print("[+] Updated .gitignore with cache and telemetry exclusions.")
    else:
        print("[+] .gitignore already up to date.")

if __name__ == "__main__":
    update_gitignore()
