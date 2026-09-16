#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Master Status Matrix & Telemetry Reporter
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import json
import platform
import shutil
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
MATRIX_REPORT = os.path.join(WORKSPACE_DIR, "status_matrix_report.json")

def gather_metrics():
    total, used, free = shutil.disk_usage(WORKSPACE_DIR)
    load1, load5, load15 = os.getloadavg() if hasattr(os, "getloadavg") else (0.0, 0.0, 0.0)
    
    metrics = {
        "timestamp": datetime.datetime.now().isoformat(),
        "platform": f"{platform.system()} {platform.release()}",
        "architecture": platform.machine(),
        "python_version": platform.python_version(),
        "disk_total_gb": total // (2**30),
        "disk_used_gb": used // (2**30),
        "disk_usage_pct": round(used / total * 100, 2),
        "cpu_load_avg": [load1, load5, load15],
        "status": "NOMINAL"
    }
    return metrics

def main():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - MASTER STATUS MATRIX")
    print(" EB Enterprises | Automated Terminal Environment")
    print("=============================================================")
    
    metrics = gather_metrics()
    for k, v in metrics.items():
        print(f" {k:<20} : {v}")
        
    with open(MATRIX_REPORT, "w") as f:
        json.dump(metrics, f, indent=2)
        
    print("------------------------------------------------------------R")
    print(f"[+] Status matrix report written to {MATRIX_REPORT}")
    print("=============================================================")

if __name__ == "__main__":
    main()
