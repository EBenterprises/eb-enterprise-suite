#!/usr/bin/env python3
import os
import json
import socket
import datetime

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')

SERVICES = [
    {"name": "Executive Web UI", "port": 8080},
    {"name": "Local Telemetry Relay", "port": 9090}
]

def check_port(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(1)
        return s.connect_ex(('127.0.0.1', port)) == 0

def scan_topology():
    topology = {
        "timestamp": datetime.datetime.now().isoformat(),
        "services": []
    }
    
    for svc in SERVICES:
        active = check_port(svc['port'])
        topology["services"].append({
            "name": svc['name'],
            "port": svc['port'],
            "active": active
        })
        
    report_path = os.path.join(WORKSPACE_DIR, 'network_topology.json')
    with open(report_path, 'w') as f:
        json.dump(topology, f, indent=2)
    print(json.dumps(topology, indent=2))

if __name__ == '__main__':
    scan_topology()
