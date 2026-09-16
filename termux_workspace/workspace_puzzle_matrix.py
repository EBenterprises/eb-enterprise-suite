#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Puzzle & System Completeness Matrix
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import json
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
MATRIX_REPORT = os.path.join(WORKSPACE_DIR, "puzzle_matrix_status.json")

def evaluate_puzzle_pieces():
    components = {
        "Core Microkernels & Infrastructure": {
            "workspace_master_pipeline.sh": "Active",
            "workspace_master_orchestrator.sh": "Active",
            "exec-spec": "Active"
        },
        "Autonomous Automation & Engines": {
            "workspace_work_engine.py": "Active",
            "workspace_optimizer.py": "Active",
            "workspace_bootstrap_factory.py": "Active"
        },
        "Synchronization & Watchdogs": {
            "workspace_remote_sync_watchdog.py": "Active",
            "workspace_auto_recovery.py": "Active"
        },
        "Telemetry & Health Dashboards": {
            "workspace_health_dashboard.py": "Active",
            "workspace_deployment_gateway.py": "Active",
            "workspace_ecosystem_master_controller.py": "Active"
        }
    }

    total_items = sum(len(sub) for sub in components.values())
    active_items = sum(1 for sub in components.values() for file, status in sub.items() if os.path.exists(os.path.join(WORKSPACE_DIR, file)))
    
    # Final puzzle completion metrics
    remaining_pieces = max(0, total_items - active_items)
    completion_percentage = round((active_items / total_items) * 100, 2)

    status_data = {
        "timestamp": datetime.datetime.now().isoformat(),
        "total_ecosystem_components": total_items,
        "active_components": active_items,
        "remaining_puzzle_pieces": remaining_pieces,
        "completion_percentage": completion_percentage,
        "components": components,
        "ecosystem_status": "FULLY ASSEMBLED AND OPERATIONAL" if remaining_pieces == 0 else "OPTIMIZATION IN PROGRESS"
    }

    with open(MATRIX_REPORT, "w") as f:
        json.dump(status_data, f, indent=2)

    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - PUZZLE COMPLETION MATRIX")
    print(f" Status: {status_data['ecosystem_status']}")
    print(f" Active Subsystems: {active_items}/{total_items} ({completion_percentage}%)")
    print(f" Remaining Puzzle Pieces: {remaining_pieces}")
    print("=============================================================")

if __name__ == "__main__":
    evaluate_puzzle_pieces()
