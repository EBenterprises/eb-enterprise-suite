#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Comprehensive Health Dashboard & Telemetry Visualizer
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import json
import shutil
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
DASHBOARD_REPORT = os.path.join(WORKSPACE_DIR, "executive_health_dashboard.json")

def compile_health_metrics():
    total, used, free = shutil.disk_usage(WORKSPACE_DIR)
    
    # Check key logs
    logs = ["scheduler.log", "work_engine.log", "optimizer.log", "watchdog.log", "orchestrator.log"]
    log_status = {}
    for log in logs:
        path = os.path.join(WORKSPACE_DIR, log)
        if os.path.exists(path):
            size_kb = round(os.path.getsize(path) / 1024, 2)
            mtime = datetime.datetime.fromtimestamp(os.path.getmtime(path)).isoformat()
            log_status[log] = {"status": "ACTIVE", "size_kb": size_kb, "last_modified": mtime}
        else:
            log_status[log] = {"status": "MISSING", "size_kb": 0, "last_modified": None}

    # Check pid
    pid_path = os.path.join(WORKSPACE_DIR, ".vault", "orchestrator.pid")
    orchestrator_running = False
    pid_val = None
    if os.path.exists(pid_path):
        with open(pid_path, "r") as f:
            pid_str = f.read().strip()
            if pid_str.isdigit():
                pid_val = int(pid_str)
                orchestrator_running = os.path.exists(f"/proc/{pid_val}")

    dashboard = {
        "timestamp": datetime.datetime.now().isoformat(),
        "environment": "Executive Spectrum | EB Enterprises",
        "storage_utilization": {
            "total_gb": round(total / (1024**3), 2),
            "used_gb": round(used / (1024**3), 2),
            "free_gb": round(free / (1024**3), 2),
            "pct": round(used / total * 100, 2)
        },
        "orchestrator_daemon": {
            "running": orchestrator_running,
            "pid": pid_val
        },
        "subsystems": log_status,
        "overall_status": "NOMINAL" if orchestrator_running else "DEGRADED"
    }

    with open(DASHBOARD_REPORT, "w") as f:
        json.dump(dashboard, f, indent=2)

    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - HEALTH DASHBOARD COMPILED")
    print(f" Status: {dashboard['overall_status']}")
    print(f" Report Path: {DASHBOARD_REPORT}")
    print("=============================================================")

if __name__ == "__main__":
    compile_health_metrics()
