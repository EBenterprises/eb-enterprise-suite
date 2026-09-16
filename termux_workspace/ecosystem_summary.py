#!/usr/bin/env python3
import os
import json
import datetime

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')

def generate_summary():
    components = [
        ("master_orchestrator.py", "Master Workspace Lifecycle Manager"),
        ("system_health_matrix.py", "System Diagnostics & Metrics Matrix"),
        ("snippet_store.py", "SQLite Code Snippet Manager"),
        ("snippet_runner.py", "Secure Snippet Execution Engine"),
        ("dashboard_tui.py", "Interactive Terminal UI Dashboard"),
        ("web_ui_dashboard.py", "Executive Web UI Dashboard Server"),
        ("telemetry_stream.py", "Real-Time Telemetry & Event Stream"),
        ("notification_relay.py", "Local Event & Webhook Relay"),
        ("log_analyzer.py", "Log Intelligence & Rotation Engine"),
        ("network_topology.py", "Service & Port Topology Scanner"),
        ("self_diagnostics.py", "Self-Diagnostic & Repair Suite"),
        ("bootstrap_verify.py", "Master Environment Verification Protocol")
    ]

    summary = {
        "timestamp": datetime.datetime.now().isoformat(),
        "total_components": len(components),
        "components": [{"file": f, "description": d, "status": "ONLINE" if os.path.exists(os.path.join(WORKSPACE_DIR, f)) else "MISSING"} for f, d in components]
    }

    print(json.dumps(summary, indent=2))
    
    report_path = os.path.join(WORKSPACE_DIR, 'ecosystem_summary.json')
    with open(report_path, 'w') as f:
        json.dump(summary, f, indent=2)

if __name__ == '__main__':
    generate_summary()
