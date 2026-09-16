#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - AliasPlug® Domain & Service Router
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import json
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
ALIAS_CONFIG = os.path.join(WORKSPACE_DIR, "alias_plug_routes.json")

DEFAULT_ROUTES = {
    "sales.aliasplug.local": {"port": 8080, "service": "Sales Ledger API"},
    "health.aliasplug.local": {"port": 8081, "service": "Health Dashboard API"},
    "matrix.aliasplug.local": {"port": 8082, "service": "Puzzle Matrix API"},
    "events.aliasplug.local": {"port": 8083, "service": "Event Bus Telemetry"}
}

def init_plug():
    if not os.path.exists(ALIAS_CONFIG):
        with open(ALIAS_CONFIG, "w") as f:
            json.dump(DEFAULT_ROUTES, f, indent=2)

def run_plug():
    init_plug()
    with open(ALIAS_CONFIG, "r") as f:
        routes = json.load(f)

    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - ALIASPLUG® ROUTING ENGINE")
    print(" EB Enterprises | Automated Terminal Environment")
    print("=============================================================")
    print("[+] Active AliasPlug Endpoints & Port Bindings:")
    for domain, info in routes.items():
        print(f"    - {domain} --> http://127.0.0.1:{info['port']} ({info['service']})")
    print("=============================================================")
    print("[+] AliasPlug router successfully initialized and active.")
    print("=============================================================")

if __name__ == "__main__":
    run_plug()
