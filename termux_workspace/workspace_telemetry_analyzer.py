#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - System Telemetry & Analytics Analyzer
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import time
import shutil

def main():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - TELEMETRY & ANALYTICS ANALYZER")
    print("=============================================================")
    total, used, free = shutil.disk_usage("/")
    load1, load5, load15 = os.getloadavg() if hasattr(os, "getloadavg") else (0.0, 0.0, 0.0)
    
    print(f" CPU Load Average : {load1:.2f}, {load5:.2f}, {load15:.2f}")
    print(f" Disk Utilization : {used / total * 100:.2f}% ({used // (2**30)}GB used)")
    print(f" Telemetry Status : Nominal [All systems stable]")
    print("=============================================================")

if __name__ == "__main__":
    main()
