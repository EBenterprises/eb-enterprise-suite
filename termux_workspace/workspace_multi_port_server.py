#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Multi-Port Application & Service Cluster
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import json
import threading
import http.server
import socketserver
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
SERVER_LOG = os.path.join(WORKSPACE_DIR, "multi_port_server.log")

PORT_SERVICES = {
    8080: {"name": "Sales Ledger API", "file": "sales_ledger.json"},
    8081: {"name": "Health Dashboard API", "file": "executive_health_dashboard.json"},
    8082: {"name": "Puzzle Matrix API", "file": "puzzle_matrix_status.json"},
    8083: {"name": "Event Bus Telemetry", "file": ".vault/event_queue.json"}
}

def log_server(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] {message}"
    print(entry)
    with open(SERVER_LOG, "a") as f:
        f.write(entry + "\n")

class ExecutiveSpectrumHandler(http.server.SimpleHTTPRequestHandler):
    target_file = None

    def do_GET(self):
        file_path = os.path.join(WORKSPACE_DIR, self.target_file)
        if os.path.exists(file_path):
            try:
                with open(file_path, "rb") as f:
                    content = f.read()
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.send_header("Content-Length", str(len(content)))
                self.end_headers()
                self.wfile.write(content)
            except Exception as e:
                self.send_error(500, str(e))
        else:
            self.send_error(404, "Data file not found or zeroized.")

    def log_message(self, format, *args):
        # Suppress default stderr logs to keep terminal clean
        pass

def start_server(port, name, filename):
    class CustomHandler(ExecutiveSpectrumHandler):
        target_file = filename

    try:
        with socketserver.TCPServer(("", port), CustomHandler) as httpd:
            log_server(f"[+] Started '{name}' on port {port} (serving {filename})")
            httpd.serve_forever()
    except Exception as e:
        log_server(f"[-] Failed to start {name} on port {port}: {e}")

def main():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - MULTI-PORT SERVICE CLUSTER")
    print(" EB Enterprises | Automated Terminal Environment")
    print("=============================================================")

    threads = []
    for port, info in PORT_SERVICES.items():
        t = threading.Thread(target=start_server, args=(port, info["name"], info["file"]), daemon=True)
        t.start()
        threads.append(t)

    log_server("[+] All application services dispatched across designated ports.")
    print("=============================================================")
    print("[+] Active Ports:")
    for port, info in PORT_SERVICES.items():
        print(f"    - Port {port}: {info['name']} ({info['file']})")
    print("=============================================================")

    # Keep main thread alive
    try:
        import time
        while True:
            time.sleep(3600)
    except KeyboardInterrupt:
        print("\n[!] Shutting down multi-port service cluster.")

if __name__ == "__main__":
    main()
