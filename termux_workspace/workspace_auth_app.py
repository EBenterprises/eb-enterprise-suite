#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Authenticated Portal & Sales Dashboard App
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import json
import http.server
import socketserver
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
PORT = 8084
USERS_FILE = os.path.join(WORKSPACE_DIR, ".vault", "users.json")
SALES_LEDGER = os.path.join(WORKSPACE_DIR, "sales_ledger.json")

def init_users():
    os.makedirs(os.path.dirname(USERS_FILE), exist_ok=True)
    if not os.path.exists(USERS_FILE):
        default_users = {
            "admin": "executive2026",
            "manager": "spectrum77"
        }
        with open(USERS_FILE, "w") as f:
            json.dump(default_users, f, indent=2)

class AuthHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/" or self.path == "/login":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            html = """<!DOCTYPE html>
<html>
<head>
    <title>Executive Spectrum - Login Portal</title>
    <style>
        body { font-family: monospace; background: #0d1117; color: #c9d1d9; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .login-box { background: #161b22; padding: 40px; border-radius: 8px; border: 1px solid #30363d; width: 320px; box-shadow: 0 8px 24px rgba(0,0,0,0.5); }
        h2 { color: #58a6ff; text-align: center; margin-bottom: 20px; }
        label { display: block; margin-bottom: 8px; font-size: 14px; }
        input { width: 100%; padding: 10px; margin-bottom: 20px; background: #0d1117; border: 1px solid #30363d; border-radius: 4px; color: #c9d1d9; box-sizing: border-box; }
        button { width: 100%; padding: 10px; background: #238636; border: none; border-radius: 4px; color: white; font-weight: bold; cursor: pointer; }
        button:hover { background: #2ea043; }
        .error { color: #f85149; text-align: center; margin-bottom: 15px; font-size: 13px; }
    </style>
</head>
<body>
    <div class="login-box">
        <h2>Executive Spectrum</h2>
        <form action="/auth" method="POST">
            <label>Username</label>
            <input type="text" name="username" required autocomplete="off">
            <label>Password</label>
            <input type="password" name="password" required>
            <button type="submit">Authenticate</button>
        </form>
    </div>
</body>
</html>"""
            self.wfile.write(html.encode("utf-8"))
        elif self.path == "/dashboard":
            # Read sales ledger
            ledger = []
            if os.path.exists(SALES_LEDGER):
                try:
                    with open(SALES_LEDGER, "r") as f:
                        ledger = json.load(f)
                except Exception:
                    ledger = []
            
            grand_total = sum(s.get('total_price', 0.0) for s in ledger)
            grand_weight = sum(s.get('total_weight_grams', 0.0) for s in ledger)

            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            
            rows = ""
            for s in ledger:
                w_info = f"{s.get('total_weight_grams', 0.0)}g" if s.get('weight_grams', 0.0) > 0 else "-"
                rows += f"<tr><td>{s['id']}</td><td>{s['timestamp'][:10]}</td><td>{s['category']}</td><td>{s['quantity']}x {s['item']}</td><td>${s['unit_price']:.2f}</td><td>${s['total_price']:.2f}</td><td>{w_info}</td></tr>"

            html = f"""<!DOCTYPE html>
<html>
<head>
    <title>Executive Spectrum - Dashboard</title>
    <style>
        body {{ font-family: monospace; background: #0d1117; color: #c9d1d9; padding: 40px; margin: 0; }}
        h1 {{ color: #58a6ff; }}
        .stats {{ display: flex; gap: 20px; margin-bottom: 30px; }}
        .card {{ background: #161b22; border: 1px solid #30363d; padding: 20px; border-radius: 8px; flex: 1; }}
        .card h3 {{ margin: 0 0 10px 0; color: #8b949e; font-size: 14px; }}
        .card p {{ margin: 0; font-size: 24px; color: #238636; font-weight: bold; }}
        table {{ width: 100%; border-collapse: collapse; background: #161b22; border-radius: 8px; overflow: hidden; border: 1px solid #30363d; }}
        th, td {{ padding: 12px 15px; text-align: left; border-bottom: 1px solid #30363d; font-size: 14px; }}
        th {{ background: #21262d; color: #58a6ff; }}
        tr:hover {{ background: #1f6feb1a; }}
        .logout {{ display: inline-block; margin-top: 20px; padding: 8px 16px; background: #da3633; color: white; text-decoration: none; border-radius: 4px; font-weight: bold; }}
    </style>
</head>
<body>
    <h1>Executive Spectrum - Secure Sales & Weight Dashboard</h1>
    <div class="stats">
        <div class="card">
            <h3>TOTAL REVENUE</h3>
            <p>${grand_total:.2f}</p>
        </div>
        <div class="card">
            <h3>TOTAL MASS LOGGED</h3>
            <p>{grand_weight}g</p>
        </div>
        <div class="card">
            <h3>TOTAL TRANSACTIONS</h3>
            <p>{len(ledger)}</p>
        </div>
    </div>
    <table>
        <tr><th>ID</th><th>Date</th><th>Category</th><th>Item</th><th>Unit Price</th><th>Total</th><th>Weight</th></tr>
        {rows if rows else '<tr><td colspan="7" style="text-align:center;">No sales recorded yet.</td></tr>'}
    </table>
    <a href="/" class="logout">Sign Out</a>
</body>
</html>"""
            self.wfile.write(html.encode("utf-8"))
        else:
            self.send_error(404, "Not Found")

    def do_POST(self):
        if self.path == "/auth":
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length).decode('utf-8')
            params = {}
            for pair in post_data.split('&'):
                if '=' in pair:
                    k, v = pair.split('=', 1)
                    import urllib.parse
                    params[k] = urllib.parse.unquote_plus(v)
            
            username = params.get('username', '')
            password = params.get('password', '')

            with open(USERS_FILE, "r") as f:
                users = json.load(f)

            if username in users and users[username] == password:
                # Redirect to dashboard
                self.send_response(303)
                self.send_header('Location', '/dashboard')
                self.end_headers()
            else:
                # Failed login redirect with error
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.end_headers()
                error_html = """<!DOCTYPE html>
<html>
<head>
    <title>Login Failed</title>
    <style>
        body { font-family: monospace; background: #0d1117; color: #c9d1d9; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .box { background: #161b22; padding: 30px; border-radius: 8px; border: 1px solid #30363d; text-align: center; }
        h2 { color: #f85149; }
        a { color: #58a6ff; text-decoration: none; display: inline-block; margin-top: 15px; }
    </style>
</head>
<body>
    <div class="box">
        <h2>Authentication Failed</h2>
        <p>Invalid username or password.</p>
        <a href="/">Back to Login</a>
    </div>
</body>
</html>"""
                self.wfile.write(error_html.encode("utf-8"))

def main():
    init_users()
    print("=============================================================")
    print(f" EXECUTIVE SPECTRUM - AUTHENTICATED PORTAL RUNNING ON PORT {PORT}")
    print(" Default Credentials:")
    print("   - Username: admin | Password: executive2026")
    print("   - Username: manager | Password: spectrum77")
    print("=============================================================")
    
    with socketserver.TCPServer(("", PORT), AuthHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[!] Shutting down authentication portal.")

if __name__ == "__main__":
    main()
