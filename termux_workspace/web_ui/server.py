#!/usr/bin/env python3
import http.server
import socketserver
import os
import subprocess
import json
from datetime import datetime

PORT = 8080
WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")

class DashboardHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/' or self.path == '/index.html':
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(self.get_html().encode('utf-8'))
        elif self.path == '/api/status':
            self.send_response(200)
            self.send_header("Content-type", "application/json; charset=utf-8")
            self.end_headers()
            self.wfile.write(json.dumps(self.get_status_data()).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"404 Not Found")

    def log_message(self, format, *args):
        return

    def get_status_data(self):
        os.chdir(WORKSPACE_DIR)
        def run_cmd(cmd):
            try:
                res = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                return res.stdout.strip()
            except:
                return "N/A"

        git_status = run_cmd("git status --short")
        git_branch = run_cmd("git branch --show-current")
        git_remote = run_cmd("git remote get-url origin")
        
        daemons = ["workspace_status.sh", "clip_daemon.sh", "run_cron_scheduler.sh"]
        daemon_status = {}
        for d in daemons:
            pid = run_cmd(f"pgrep -f {d}")
            daemon_status[d] = f"Running (PID: {pid})" if pid != "N/A" else "Stopped"

        return {
            "time": datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            "branch": git_branch if git_branch else "main",
            "remote": git_remote if git_remote else "N/A",
            "status": "Clean" if not git_status else "Uncommitted Changes",
            "git_changes": git_status.splitlines() if git_status else [],
            "daemons": daemon_status
        }

    def get_html(self):
        return """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Termux Workspace Executive Dashboard</title>
    <style>
        :root {
            --bg-color: #0b0f12;
            --card-bg: #13181d;
            --accent-teal: #00d2c4;
            --accent-gold: #f4d06f;
            --text-main: #e2e8f0;
            --text-muted: #8892b0;
        }
        body {
            background-color: var(--bg-color);
            color: var(--text-main);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
        }
        header {
            border-bottom: 2px solid var(--accent-teal);
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        h1 {
            color: var(--accent-teal);
            font-size: 1.8rem;
            margin: 0;
        }
        .time {
            color: var(--text-muted);
            font-size: 0.9rem;
        }
        .card {
            background-color: var(--card-bg);
            border: 1px solid #1e262c;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        }
        h2 {
            color: var(--accent-gold);
            font-size: 1.2rem;
            margin-top: 0;
        }
        ul {
            padding-left: 20px;
            color: var(--text-muted);
        }
        li {
            margin-bottom: 5px;
        }
        .status-badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-weight: bold;
            font-size: 0.85rem;
        }
        .running { background-color: rgba(0, 210, 196, 0.15); color: var(--accent-teal); }
        .stopped { background-color: rgba(239, 68, 68, 0.15); color: #ef4444; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Termux Workspace Executive Dashboard</h1>
            <div class="time" id="time">Loading time...</div>
        </header>
        
        <div class="card">
            <h2>Git Repository Overview</h2>
            <p><strong>Branch:</strong> <span id="branch">...</span></p>
            <p><strong>Remote:</strong> <span id="remote">...</span></p>
            <p><strong>Workspace Status:</strong> <span id="git-status">...</span></p>
            <ul id="git-changes"></ul>
        </div>

        <div class="card">
            <h2>Background Daemons</h2>
            <ul id="daemons"></ul>
        </div>
    </div>

    <script>
        async function fetchStatus() {
            try {
                const res = await fetch('/api/status');
                const data = await res.json();
                
                document.getElementById('time').innerText = `Last Refreshed: ${data.time}`;
                document.getElementById('branch').innerText = data.branch;
                document.getElementById('remote').innerText = data.remote;
                document.getElementById('git-status').innerText = data.status;
                
                const changesList = document.getElementById('git-changes');
                changesList.innerHTML = '';
                if (data.git_changes.length === 0) {
                    const li = document.createElement('li');
                    li.innerText = "Working tree clean";
                    changesList.appendChild(li);
                } else {
                    data.git_changes.forEach(change => {
                        const li = document.createElement('li');
                        li.innerText = change;
                        changesList.appendChild(li);
                    });
                }
                
                const daemonsList = document.getElementById('daemons');
                daemonsList.innerHTML = '';
                for (const [name, status] of Object.entries(data.daemons)) {
                    const li = document.createElement('li');
                    const isRunning = status.startsWith('Running');
                    li.innerHTML = `<strong>${name}:</strong> <span class="status-badge ${isRunning ? 'running' : 'stopped'}">${status}</span>`;
                    daemonsList.appendChild(li);
                }
            } catch (err) {
                console.error("Failed to fetch status", err);
            }
        }
        
        fetchStatus();
        setInterval(fetchStatus, 5000);
    </script>
</body>
</html>
"""

class ThreadedHTTPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True
    daemon_threads = True

if __name__ == '__main__':
    with ThreadedHTTPServer(('127.0.0.1', PORT), DashboardHandler) as httpd:
        print(f"Server operational on http://127.0.0.1:{PORT}")
        httpd.serve_forever()
