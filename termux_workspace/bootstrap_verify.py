#!/usr/bin/env python3
import os
import sys
import subprocess
import json
import datetime

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')

REQUIRED_FILES = [
    'master_orchestrator.py',
    'system_health_matrix.py',
    'snippet_store.py',
    'snippet_runner.py',
    'dashboard_tui.py',
    'web_ui_dashboard.py',
    'telemetry_stream.py',
    'notification_relay.py',
    'log_analyzer.py',
    'network_topology.py',
    'self_diagnostics.py'
]

def verify_environment():
    missing = []
    present = []
    for f in REQUIRED_FILES:
        path = os.path.join(WORKSPACE_DIR, f)
        if os.path.exists(path):
            present.append(f)
        else:
            missing.append(f)

    status = {
        "timestamp": datetime.datetime.now().isoformat(),
        "workspace_path": WORKSPACE_DIR,
        "present_components": present,
        "missing_components": missing,
        "bootstrap_status": "VERIFIED" if not missing else "INCOMPLETE"
    }
    
    print(json.dumps(status, indent=2))
    
    report_path = os.path.join(WORKSPACE_DIR, 'bootstrap_report.json')
    with open(report_path, 'w') as f:
        json.dump(status, f, indent=2)

if __name__ == '__main__':
    verify_environment()
