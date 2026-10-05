from flask import Flask, render_template_string

app = Flask(__name__)

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enterprise P2P Sales Tracker v5</title>
    <style>
        :root {
            --bg-color: #0d1117;
            --card-bg: #161b22;
            --border-color: #30363d;
            --accent-color: #238636;
            --accent-hover: #2ea043;
            --text-main: #c9d1d9;
            --text-muted: #8b949e;
            --status-online: #3fb950;
            --status-offline: #f85149;
        }

        body {
            margin: 0;
            padding: 24px;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-main);
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 16px;
            margin-bottom: 24px;
        }

        .header h1 {
            margin: 0;
            font-size: 1.5rem;
            letter-spacing: -0.5px;
        }

        .status-badge {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 0.875rem;
            background: #21262d;
            padding: 6px 12px;
            border-radius: 20px;
            border: 1px solid var(--border-color);
        }

        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background-color: var(--status-online);
        }

        .grid {
            display: grid;
            grid-template-columns: 1fr 2fr;
            gap: 24px;
        }

        @media (max-width: 900px) {
            .grid {
                grid-template-columns: 1fr;
            }
        }

        .card {
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 6px;
            padding: 20px;
        }

        .card h2 {
            margin-top: 0;
            font-size: 1.1rem;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 10px;
            margin-bottom: 16px;
        }

        .form-group {
            margin-bottom: 14px;
        }

        label {
            display: block;
            font-size: 0.85rem;
            color: var(--text-muted);
            margin-bottom: 6px;
        }

        input, select {
            width: 100%;
            padding: 8px 12px;
            background: #0d1117;
            border: 1px solid var(--border-color);
            border-radius: 6px;
            color: var(--text-main);
            box-sizing: border-box;
        }

        button {
            width: 100%;
            padding: 10px;
            background-color: var(--accent-color);
            color: #fff;
            border: none;
            border-radius: 6px;
            font-weight: 600;
            cursor: pointer;
            margin-top: 8px;
        }

        button:hover {
            background-color: var(--accent-hover);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
            font-size: 0.9rem;
        }

        th, td {
            padding: 10px;
            border-bottom: 1px solid var(--border-color);
        }

        th {
            color: var(--text-muted);
            font-weight: 500;
        }

        .connection-box {
            background: #0d1117;
            border: 1px dashed var(--border-color);
            padding: 12px;
            border-radius: 6px;
            font-family: monospace;
            font-size: 0.85rem;
            word-break: break-all;
            margin-bottom: 12px;
        }
    </style>
</head>
<body>

    <div class="header">
        <h1>Enterprise P2P Sales Tracker <span style="font-size: 0.8rem; color: var(--text-muted);">v5</span></h1>
        <div class="status-badge">
            <div class="status-dot"></div>
            <span>P2P Node Active</span>
        </div>
    </div>

    <div class="grid">
        <div class="sidebar">
            <div class="card" style="margin-bottom: 24px;">
                <h2>WebRTC Direct Sync</h2>
                <label>Node Signaling ID</label>
                <div class="connection-box" id="node-id">p2p-node-8f92a10c</div>
                <div class="form-group">
                    <label>Peer Connection Token</label>
                    <input type="text" id="peerToken" placeholder="Paste remote peer token...">
                </div>
                <button onclick="connectPeer()">Establish Connection</button>
            </div>

            <div class="card">
                <h2>Record Transaction</h2>
                <div class="form-group">
                    <label>Client / Identifier</label>
                    <input type="text" id="client" placeholder="e.g. Enterprise Client A">
                </div>
                <div class="form-group">
                    <label>Amount ($)</label>
                    <input type="number" id="amount" placeholder="0.00">
                </div>
                <div class="form-group">
                    <label>Region / Location</label>
                    <input type="text" id="location" placeholder="e.g. BC Node 01">
                </div>
                <button onclick="addEntry()">Sync to Ledger</button>
            </div>
        </div>

        <div class="main">
            <div class="card">
                <h2>Live Peer-to-Peer Ledger</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Timestamp</th>
                            <th>Client</th>
                            <th>Location</th>
                            <th>Amount</th>
                            <th>P2P Sync Status</th>
                        </tr>
                    </thead>
                    <tbody id="ledger-body">
                        <tr>
                            <td>2026-10-03 09:10</td>
                            <td>Initial Sovereign Node</td>
                            <td>West Kelowna</td>
                            <td>$0.00</td>
                            <td><span style="color: var(--status-online);">● Synced</span></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        function connectPeer() {
            const token = document.getElementById('peerToken').value;
            if(!token) return alert('Enter a valid peer token.');
            alert('Connecting to peer node via WebRTC data channel...');
        }

        function addEntry() {
            const client = document.getElementById('client').value || 'Direct Peer';
            const amount = parseFloat(document.getElementById('amount').value || 0).toFixed(2);
            const location = document.getElementById('location').value || 'Local Node';
            
            const tbody = document.getElementById('ledger-body');
            const now = new Date().toISOString().replace('T', ' ').substring(0, 16);
            
            const row = `<tr>
                <td>${now}</td>
                <td>${client}</td>
                <td>${location}</td>
                <td>$${amount}</td>
                <td><span style="color: var(--status-online);">● Synced</span></td>
            </tr>`;
            
            tbody.innerHTML = row + tbody.innerHTML;
            document.getElementById('client').value = '';
            document.getElementById('amount').value = '';
            document.getElementById('location').value = '';
        }
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
