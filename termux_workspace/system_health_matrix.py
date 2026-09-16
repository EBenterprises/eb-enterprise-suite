#!/usr/bin/env python3
import os
import subprocess
import shutil
import json
import datetime

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')

def get_disk_usage():
    total, used, free = shutil.disk_usage(WORKSPACE_DIR)
    return {
        "total_gb": round(total / (2**30), 2),
        "used_gb": round(used / (2**30), 2),
        "free_gb": round(free / (2**30), 2),
        "percent_free": round((free / total) * 100, 2)
    }

def get_git_status():
    try:
        branch = subprocess.check_output(['git', 'rev-parse', '--abbrev-ref', 'HEAD'], cwd=WORKSPACE_DIR, text=True).strip()
        commit = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD'], cwd=WORKSPACE_DIR, text=True).strip()
        status = subprocess.check_output(['git', 'status', '--porcelain'], cwd=WORKSPACE_DIR, text=True).strip()
        return {
            "branch": branch,
            "latest_commit": commit,
            "clean_working_tree": len(status) == 0
        }
    except Exception as e:
        return {"error": str(e)}

def get_active_daemons():
    daemons = []
    for proc in ['workspace_daemon.py', 'server.py', 'app.py', 'run_cron_scheduler.sh']:
        try:
            res = subprocess.run(['pgrep', '-f', proc], stdout=subprocess.PIPE, text=True)
            active = len(res.stdout.strip()) > 0
            daemons.append({"process": proc, "active": active})
        except Exception:
            daemons.append({"process": proc, "active": False})
    return daemons

def generate_health_report():
    report = {
        "timestamp": datetime.datetime.now().isoformat(),
        "workspace_directory": WORKSPACE_DIR,
        "disk_usage": get_disk_usage(),
        "git_status": get_git_status(),
        "daemons": get_active_daemons()
    }
    print(json.dumps(report, indent=2))
    
    report_path = os.path.join(WORKSPACE_DIR, 'health_report.json')
    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2)

if __name__ == '__main__':
    generate_health_report()
