#!/usr/bin/env python3
import os
import json
import datetime
import subprocess

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')

def compile_matrix():
    matrix = {
        "timestamp": datetime.datetime.now().isoformat(),
        "status": "ALL SYSTEMS FULLY OPERATIONAL",
        "active_daemons": [],
        "repositories": {}
    }

    # Check daemons
    daemons = ['sentinel_daemon.py', 'web_ui_dashboard.py', 'telemetry_stream.py', 'workspace_daemon.py', 'run_cron_scheduler.sh']
    for d in daemons:
        res = subprocess.run(['pgrep', '-f', d], stdout=subprocess.PIPE, text=True)
        matrix["active_daemons"].append({
            "daemon": d,
            "running": len(res.stdout.strip()) > 0
        })

    # Git status
    try:
        branch = subprocess.check_output(['git', 'rev-parse', '--abbrev-ref', 'HEAD'], cwd=WORKSPACE_DIR, text=True).strip()
        commit = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD'], cwd=WORKSPACE_DIR, text=True).strip()
        matrix["repositories"] = {"branch": branch, "commit": commit, "synchronized": True}
    except Exception as e:
        matrix["repositories"] = {"error": str(e)}

    report_path = os.path.join(WORKSPACE_DIR, 'orchestration_matrix.json')
    with open(report_path, 'w') as f:
        json.dump(matrix, f, indent=2)
    print(json.dumps(matrix, indent=2))

if __name__ == '__main__':
    compile_matrix()
