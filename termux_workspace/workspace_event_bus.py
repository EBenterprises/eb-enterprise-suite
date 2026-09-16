#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Inter-Process Event Bus & Telemetry Dispatcher
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import json
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
EVENT_LOG = os.path.join(WORKSPACE_DIR, "event_bus.log")
EVENT_QUEUE = os.path.join(WORKSPACE_DIR, ".vault", "event_queue.json")

def emit_event(event_type, source, payload):
    timestamp = datetime.datetime.now().isoformat()
    event = {
        "timestamp": timestamp,
        "event_type": event_type,
        "source": source,
        "payload": payload
    }
    
    # Append to log
    log_entry = f"[{timestamp}] [{event_type.upper()}] ({source}) -> {json.dumps(payload)}"
    print(log_entry)
    with open(EVENT_LOG, "a") as f:
        f.write(log_entry + "\n")

    # Update queue store
    queue = []
    if os.path.exists(EVENT_QUEUE):
        try:
            with open(EVENT_QUEUE, "r") as f:
                queue = json.load(f)
        except Exception:
            queue = []
    
    queue.append(event)
    # Keep last 100 events
    if len(queue) > 100:
        queue = queue[-100:]
        
    os.makedirs(os.path.dirname(EVENT_QUEUE), exist_ok=True)
    with open(EVENT_QUEUE, "w") as f:
        json.dump(queue, f, indent=2)

def main():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - INTER-PROCESS EVENT BUS")
    print(" EB Enterprises | Automated Terminal Environment")
    print("=============================================================")
    
    emit_event("SYSTEM_BOOT", "event_bus", {"status": "initialized", "target": "termux_workspace"})
    
    print("=============================================================")
    print("[+] Event bus initialized and listening for subsystem traffic.")
    print("=============================================================")

if __name__ == "__main__":
    main()
