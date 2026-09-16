#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Data Zeroization & Reset Utility
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import subprocess
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")

DATA_FILES = [
    "sales_ledger.json",
    "executive_health_dashboard.json",
    "puzzle_matrix_status.json",
    "scheduler.log",
    "work_engine.log",
    "optimizer.log",
    "watchdog.log",
    "orchestrator.log",
    "recovery.log",
    "master_controller.log",
    "deployment_gateway.log",
    "ecosystem_supervisor.log",
    "final_frontier.log",
    "event_bus.log",
    ".vault/event_queue.json",
    ".vault/orchestrator.pid"
]

def zero_all_data():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - DATA ZEROIZATION UTILITY")
    print(" EB Enterprises | Automated Terminal Environment")
    print("=============================================================")

    for rel_path in DATA_FILES:
        path = os.path.join(WORKSPACE_DIR, rel_path)
        if os.path.exists(path):
            if path.endswith(".json") and "sales_ledger" in path:
                with open(path, "w") as f:
                    f.write("[]\n")
                print(f"[+] Zeroized ledger: {rel_path}")
            elif path.endswith(".json"):
                with open(path, "w") as f:
                    f.write("{}\n")
                print(f"[+] Reset JSON state: {rel_path}")
            else:
                os.remove(path)
                print(f"[+] Purged log/state file: {rel_path}")
        else:
            print(f"[~] Not found (skipped): {rel_path}")

    print("=============================================================")
    print("[+] All operational data successfully zeroized and reset.")
    print("=============================================================")

if __name__ == "__main__":
    zero_all_data()
