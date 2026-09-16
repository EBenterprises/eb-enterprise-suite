#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Plugin Manager
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys

PLUGINS_DIR = os.path.expanduser("~/termux_workspace/plugins")

def list_plugins():
    os.makedirs(PLUGINS_DIR, exist_ok=True)
    plugins = os.listdir(PLUGINS_DIR)
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - PLUGIN MANAGER")
    print("=============================================================")
    if not plugins:
        print(" No plugins installed.")
    else:
        for p in plugins:
            print(f"  - {p}")
    print("=============================================================")

def main():
    if len(sys.argv) < 2:
        print("Usage: ./exec-spec plugin <list|run> [plugin_name]")
        sys.exit(1)

    action = sys.argv[1]
    if action == "list":
        list_plugins()
    else:
        print(f"Unknown plugin action: {action}")
        sys.exit(1)

if __name__ == "__main__":
    main()
