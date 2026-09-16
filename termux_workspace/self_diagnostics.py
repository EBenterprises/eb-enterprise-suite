#!/usr/bin/env python3
import os
import subprocess
import json
import datetime

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')

def run_diagnostics():
    checks = []
    
    # 1. Check Python compilation of all scripts
    py_errors = 0
    for root, _, files in os.walk(WORKSPACE_DIR):
        for file in files:
            if file.endswith('.py'):
                full_path = os.path.join(root, file)
                res = subprocess.run(['python3', '-m', 'py_compile', full_path], capture_output=True)
                if res.returncode != 0:
                    py_errors += 1
    checks.append({"component": "Python Syntax Compilation", "status": "OK" if py_errors == 0 else "ERROR", "issues": py_errors})

    # 2. Check Git repository health
    git_clean = True
    try:
        status = subprocess.check_output(['git', 'status', '--porcelain'], cwd=WORKSPACE_DIR, text=True)
        # We consider working tree status informational, but check if repo is valid
        subprocess.check_output(['git', 'rev-parse', '--is-inside-work-tree'], cwd=WORKSPACE_DIR)
        git_status_ok = True
    except Exception:
        git_status_ok = False
    checks.append({"component": "Git Repository Integrity", "status": "OK" if git_status_ok else "ERROR"})

    # 3. Check SQLite DB integrity
    db_path = os.path.join(WORKSPACE_DIR, 'snippets.db')
    db_ok = True
    if os.path.exists(db_path):
        try:
            import sqlite3
            conn = sqlite3.connect(db_path)
            res = conn.execute("PRAGMA integrity_check;").fetchone()
            conn.close()
            db_ok = (res[0] == "ok")
        except Exception:
            db_ok = False
    checks.append({"component": "SQLite Snippet Database", "status": "OK" if db_ok else "WARNING"})

    report = {
        "timestamp": datetime.datetime.now().isoformat(),
        "diagnostics": checks
    }
    
    report_path = os.path.join(WORKSPACE_DIR, 'diagnostic_report.json')
    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2)
    print(json.dumps(report, indent=2))

if __name__ == '__main__':
    run_diagnostics()
