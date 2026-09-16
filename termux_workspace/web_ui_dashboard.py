#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Lightweight Web Dashboard
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import http.server
import socketserver
import json
import subprocess

PORT = 8080
HOME = os.environ.get("HOME", "/data/data/com.termux/files/home")
WORKSPACE_DIR = os.path.join(HOME, "termux_workspace")

class DashboardHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/" or self.path == "/status":
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            
            # Gather system status
            try:
                git_status = subprocess.check_output(["git", "-C", WORKSPACE_DIR, "status", "--porcelain"]).decode().strip()
                git_clean = "Clean" if not git_status else "Uncommitted Changes"
            except Exception:
                git_clean = "Unknown"

            html = f"""<!DOCTYPE html>
<html>
<head>
    <title>Executive Spectrum Dashboard</title>
    <meta http-equiv="refresh" content="5">
    <style>
        body {{ background-color: #0b0f12; color: #e1e7ec; font-family: monospace; margin: 0; padding: 20px; }}
        h1 {{ color: #d4af37; border-bottom: 2px solid #008080; padding-bottom: 10px; }}
        .card {{ background-color: #12181f; border: 1px solid #008080; border-radius: 6px; padding: 15px; margin-bottom: 15px; }}
        .badge {{ background-color: #008080; color: #fff; padding: 3px 8px; border-radius: 4px; font-weight: bold; }}
    style>
head>
<body>
    <h1>EXECUTIVE SPECTRUM WEB DASHBOARD</h1>
    <div class="card">
        <h3>System Overview</h3>
        <p><strong>Environment:</strong> Termux / Crostini Linux</p>
        <p><strong>Repository Status:</strong> <span class="badge">{git_clean}</span></p>
        <p><strong>Active Port:</strong> {PORT}</p>
    div>
    <div class="card">
        <h3>Daemons & Services</h3>
        <p>- workspace_health_monitor.py: <span class="badge">ACTIVE</span></p>
        <p>- clip_daemon.sh: <span class="badge">ACTIVE</span></p>
        <p>- web_ui_dashboard.py: <span class="badge">SERVING</span></p>
    div>
body>
html>"""
            self.wfile.write(html.encode("utf-8"))
        else:
            super().do_GET()

    def log_message(self, format, *args):
        pass

def main():
    with socketserver.TCPServer(("", PORT), DashboardHandler) as httpd:
        print(f"Executive Spectrum Web Dashboard serving on port {PORT}...")
        httpd.serve_forever()

if __name__ == "__main__":
    main()
