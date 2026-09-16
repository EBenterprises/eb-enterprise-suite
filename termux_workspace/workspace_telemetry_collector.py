#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - System Telemetry Collector & Resource Metrics
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import time
import json
import shutil
import datetime

HOME = os.environ.get("HOME", "/data/data/com.termux/files/home")
TELEMETRY_LOG = os.path.join(HOME, ".workspace_telemetry.jsonl")

def get_system_metrics():
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # Disk Usage
    total, used, free = shutil.disk_usage(HOME)
    disk_usage_percent = (used / total) * 100
    
    # Load Averages (if supported)
    load1, load5, load15 = (0.0, 0.0, 0.0)
    try:
        load1, load5, load15 = os.getloadavg()
    except (AttributeError, OSError):
        pass

    metrics = {
        "timestamp": timestamp,
        "disk_total_gb": round(total / (2**30), 2),
        "disk_used_gb": round(used / (2**30), 2),
        "disk_free_gb": round(free / (2**30), 2),
        "disk_usage_percent": round(disk_usage_percent, 2),
        "load_average": {
            "1m": load1,
            "5m": load5,
            "15m": load15
        }
    }
    return metrics

def record_telemetry():
    metrics = get_system_metrics()
    try:
        with open(TELEMETRY_LOG, "a") as f:
            f.write(json.dumps(metrics) + "\n")
        print(f"[{metrics['timestamp']}] [TELEMETRY] Recorded metrics. Disk usage: {metrics['disk_usage_percent']}%")
    except Exception as e:
        print(f"Error recording telemetry: {e}")

if __name__ == "__main__":
    record_telemetry()
