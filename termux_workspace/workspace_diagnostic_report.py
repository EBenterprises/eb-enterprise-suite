#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Diagnostic Report Aggregator
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import json
import platform
import shutil
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
REPORT_PATH = os.path.join(WORKSPACE_DIR, "executive_diagnostic_report.json")

def generate_report():
    total, used, free = shutil.disk_usage(WORKSPACE_DIR)
    
    report = {
        "generated_at": datetime.datetime.now().isoformat(),
        "environment": "Executive Spectrum | EB Enterprises",
        "host_platform": platform.platform(),
        "processor": platform.processor(),
        "python_version": platform.python_version(),
        "storage": {
            "total_bytes": total,
            "used_bytes": used,
            "free_bytes": free,
            "utilization_pct": round(used / total * 100, 2)
        },
        "workspace_path": WORKSPACE_DIR,
        "status": "NOMINAL"
    }
    
    with open(REPORT_PATH, "w") as f:
        json.dump(report, f, indent=2)
        
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - DIAGNOSTIC REPORT GENERATED")
    print(f" Output Path: {REPORT_PATH}")
    print("=============================================================")

if __name__ == "__main__":
    generate_report()
