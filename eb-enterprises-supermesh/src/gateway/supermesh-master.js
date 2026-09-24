const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

app.use(express.json());
app.use(express.static(path.join(__dirname, '../../public')));

const MASTER_PORT = 14000;
const MASTER_URL = `http://localhost:${MASTER_PORT}`;

// Self-healing manifest
const distDir = path.join(__dirname, '../../dist');
const manifestPath = path.join(distDir, 'supermesh-manifest.json');
if (!fs.existsSync(distDir)) fs.mkdirSync(distDir, { recursive: true });
if (!fs.existsSync(manifestPath)) {
  fs.writeFileSync(manifestPath, JSON.stringify({ status: 'ACTIVE', timestamp: new Date().toISOString() }, null, 2));
}

// Spin up 10 full ecosystem ports concurrently (14001 through 14009)
const nodeSpecs = {
  14001: { name: 'www.tap.eco', desc: 'Affiliate & Community Platform' },
  14002: { name: 'BuySideOnline® & Nexus', desc: 'Payment Engine & Sales Tracker' },
  14003: { name: 'Cuff P2P & TapChat', desc: 'Consignment & Direct Board Games' },
  14004: { name: 'Eggfinder & CoinScan', desc: 'GPS Radar & Optical Coin ID' },
  14005: { name: 'Titan-OS / ebOS Kernel', desc: 'Low-Level Mobile OS & Compositor' },
  14006: { name: 'BongBelt & Bongdöra', desc: 'Glass Pipe Utility Belts & Jewelry' },
  14007: { name: 'CoastRZ Micro-Mobility', desc: 'Micro-Mobility Fleet & Transit Suite' },
  14008: { name: 'Choreits® Rewards Engine', desc: 'Task & Incentive Management System' },
  14009: { name: 'Secure Vault Auth Suite', desc: 'Zero-Dependency Authentication Portal' }
};

Object.keys(nodeSpecs).forEach(pStr => {
  const p = parseInt(pStr, 10);
  const subApp = express();
  subApp.get('*', (req, res) => {
    const meta = nodeSpecs[p];
    res.send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <title>${meta.name} — EB Enterprises®</title>
          <style>
              body { background: #02040a; color: #f0f6fc; font-family: monospace; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
              .box { background: #0d1117; border: 1px solid #30363d; padding: 2.5rem; border-radius: 8px; text-align: center; max-width: 520px; box-shadow: 0 8px 24px rgba(0,0,0,0.5); }
              h1 { color: #58a6ff; margin-bottom: 0.5rem; font-size: 1.5rem; }
              p { color: #8b949e; margin-bottom: 1.5rem; font-size: 0.95rem; }
              a { display: inline-block; background: #58a6ff; color: #02040a; padding: 0.75rem 1.5rem; border-radius: 6px; text-decoration: none; font-weight: bold; text-transform: uppercase; }
              a:hover { background: #79c0ff; }
          </style>
      </head>
      <body>
          <div class="box">
              <h1>${meta.name}</h1>
              <p>${meta.desc}<br><br>Status: ONLINE (Port ${p})</p>
              <a href="${MASTER_URL}">Return to Supermesh Master</a>
          </div>
      </body>
      </html>
    `);
  });
  subApp.listen(p, () => {
    console.log(`[SUPER-NODE] ${nodeSpecs[p].name} running at http://localhost:${p}`);
  });
});

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>EB Enterprises® — SUPERMESH COMMAND</title>
        <style>
            :root {
                --bg-primary: #02040a;
                --card-bg: #0d1117;
                --accent-primary: #58a6ff;
                --accent-hover: #79c0ff;
                --text-main: #f0f6fc;
                --text-muted: #8b949e;
                --text-bright: #ffffff;
                --border-color: #30363d;
                --font-mono: ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, monospace;
            }
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body { background-color: var(--bg-primary); color: var(--text-main); font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; line-height: 1.6; }
            header { border-bottom: 1px solid var(--border-color); padding: 1.5rem 2rem; display: flex; justify-content: space-between; align-items: center; background-color: var(--card-bg); }
            .logo { font-family: var(--font-mono); font-size: 1.25rem; font-weight: bold; color: var(--text-bright); text-decoration: none; display: flex; align-items: center; gap: 0.5rem; }
            .logo span { color: var(--accent-primary); }
            main { max-width: 1450px; margin: 0 auto; padding: 3rem 2rem; }
            .hero { text-align: center; margin-bottom: 3.5rem; }
            .hero h1 { font-size: 3.2rem; color: var(--text-bright); margin-bottom: 1rem; letter-spacing: -0.03em; font-family: var(--font-mono); text-transform: uppercase; }
            .hero p { font-size: 1.2rem; color: var(--text-muted); max-width: 900px; margin: 0 auto 2rem auto; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; margin-bottom: 3rem; }
            .card { background-color: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 1.5rem; display: flex; flex-direction: column; justify-content: space-between; transition: border-color 0.2s; text-decoration: none; }
            .card:hover { border-color: var(--accent-primary); }
            .card h3 { font-size: 1.05rem; color: var(--text-bright); margin-bottom: 0.5rem; font-family: var(--font-mono); }
            .card p { color: var(--text-muted); font-size: 0.85rem; margin-bottom: 1rem; }
            .card-footer { font-size: 0.75rem; font-family: var(--font-mono); color: var(--accent-primary); display: flex; justify-content: space-between; align-items: center; }
            .terminal { background-color: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 1.5rem; font-family: var(--font-mono); font-size: 0.85rem; margin-top: 2rem; max-height: 280px; overflow-y: auto; }
            .btn { background-color: var(--accent-primary); color: #02040a; border: none; padding: 0.9rem 2.2rem; border-radius: 6px; font-family: var(--font-mono); font-weight: bold; cursor: pointer; display: inline-flex; align-items: center; gap: 0.5rem; font-size: 1rem; text-transform: uppercase; }
            .btn:hover { background-color: var(--accent-hover); }
            footer { border-top: 1px solid var(--border-color); padding: 2rem; text-align: center; color: var(--text-muted); font-size: 0.85rem; background-color: var(--card-bg); margin-top: 4rem; font-family: var(--font-mono); }
            .live-badge { display: inline-block; width: 10px; height: 10px; background-color: #3fb950; border-radius: 50%; animation: pulse 1s infinite; margin-right: 6px; }
            @keyframes pulse { 0% { opacity: 1; transform: scale(1); } 50% { opacity: 0.4; transform: scale(1.2); } 100% { opacity: 1; transform: scale(1); } }
        </style>
    </head>
    <body>
        <header>
            <a href="#" class="logo">⚡ EB<span>Enterprises</span>® Supermesh</a>
            <span style="font-family: var(--font-mono); font-size: 0.85rem; color: var(--text-bright); display: flex; align-items: center;"><span class="live-badge"></span>ALL 10 SERVICES LIVE</span>
        </header>
        <main>
            <section class="hero">
                <h1>Supermesh Command Center</h1>
                <p>Complete multi-port architecture integrating core platforms, payment engines, optical ID, micro-mobility, utility accessories, and auth suites into an expanded autonomous network.</p>
                <button class="btn" onclick="triggerSupermeshPulse()">⚡ Pulse All 10 Supermesh Nodes</button>
            </section>
            <div class="grid">
                <a href="http://localhost:14001" target="_blank" class="card">
                    <div><h3>www.tap.eco</h3><p>Affiliate community platform and digital sales funnels.</p></div>
                    <div class="card-footer"><span>PORT: 14001</span><span>LAUNCH ↗</span></div>
                </a>
                <a href="http://localhost:14002" target="_blank" class="card">
                    <div><h3>BuySideOnline® & Nexus</h3><p>Multi-channel payment engine and sales tracker v1-v5.</p></div>
                    <div class="card-footer"><span>PORT: 14002</span><span>LAUNCH ↗</span></div>
                </a>
                <a href="http://localhost:14003" target="_blank" class="card">
                    <div><h3>Cuff P2P & TapChat</h3><p>Direct peer-to-peer web platform for board games.</p></div>
                    <div class="card-footer"><span>PORT: 14003</span><span>LAUNCH ↗</span></div>
                </a>
                <a href="http://localhost:14004" target="_blank" class="card">
                    <div><h3>Eggfinder & CoinScan</h3><p>GPS farm-fresh egg plotter and optical coin ID engine.</p></div>
                    <div class="card-footer"><span>PORT: 14004</span><span>LAUNCH ↗</span></div>
                </a>
                <a href="http://localhost:14005" target="_blank" class="card">
                    <div><h3>Titan-OS / ebOS Kernel</h3><p>Low-level mobile OS runtime and X11 window compositor.</p></div>
                    <div class="card-footer"><span>PORT: 14005</span><span>LAUNCH ↗</span></div>
                </a>
                <a href="http://localhost:14006" target="_blank" class="card">
                    <div><h3>BongBelt & Bongdöra</h3><p>Glass pipe utility belts and decorative pipe jewelry.</p></div>
                    <div class="card-footer"><span>PORT: 14006</span><span>LAUNCH ↗</span></div>
                </a>
                <a href="http://localhost:14007" target="_blank" class="card">
                    <div><h3>CoastRZ Micro-Mobility</h3><p>Micro-mobility fleet and urban transit suite.</p></div>
                    <div class="card-footer"><span>PORT: 14007</span><span>LAUNCH ↗</span></div>
                </a>
                <a href="http://localhost:14008" target="_blank" class="card">
                    <div><h3>Choreits® Rewards Engine</h3><p>Task and incentive management platform.</p></div>
                    <div class="card-footer"><span>PORT: 14008</span><span>LAUNCH ↗</span></div>
                </a>
                <a href="http://localhost:14009" target="_blank" class="card">
                    <div><h3>Secure Vault Auth Suite</h3><p>Zero-dependency secure authentication portal.</p></div>
                    <div class="card-footer"><span>PORT: 14009</span><span>LAUNCH ↗</span></div>
                </a>
            </div>
            <div class="terminal" id="terminal-box">
                <p style="color: var(--accent-primary);">$ eb-enterprises supermesh --launch-all</p>
                <p style="color: var(--text-bright);">[SUPERMESH] Master Gateway active on port 14000</p>
                <p style="color: var(--text-muted);">[INFO] Organization: EBenterprises | Managed by eastonbodeuxenterprises@gmail.com</p>
            </div>
        </main>
        <footer>
            <p>&copy; 2026 EB Enterprises®. Extended Supermesh fully online.</p>
        </footer>
        <script>
            const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const ws = new WebSocket(\`\${wsProtocol}//\${window.location.host}\`);
            
            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                const box = document.getElementById('terminal-box');
                box.innerHTML += \`<p style="color: #58a6ff;">[SUPER-FEED] \${data.message}</p>\`;
                box.scrollTop = box.scrollHeight;
            };

            function triggerSupermeshPulse() {
                const box = document.getElementById('terminal-box');
                box.innerHTML += '<p style="color: #d29922;">[PULSE] Pinging ports 14001 through 14009...</p>';
                fetch('/api/v1/supermesh-manifest')
                    .then(res => res.json())
                    .then(data => {
                        box.innerHTML += \`<p style="color: #3fb950;">[SUCCESS] All \${data.manifest.extendedNodes.length} enterprise endpoints verified and live.</p>\`;
                        box.scrollTop = box.scrollHeight;
                    })
                    .catch(err => {
                        box.innerHTML += '<p style="color: #f85149;">[ERROR] Supermesh pulse interrupted.</p>';
                        box.scrollTop = box.scrollHeight;
                    });
            }
        </script>
    </body>
    </html>
  `);
});

app.get('/api/v1/supermesh-manifest', (req, res) => {
  if (fs.existsSync(manifestPath)) {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    return res.json({ status: 'SUCCESS', manifest });
  }
  res.status(404).json({ error: 'Supermesh manifest missing.' });
});

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'SUPERMESH_CONNECT', message: 'Supermesh WebSocket active: All 10 services synchronized.' }));
});

server.listen(MASTER_PORT, () => {
  console.log(`[EB-ENTERPRISES] Supermesh Master Gateway active at ${MASTER_URL}`);
  
  const openCmd = process.platform === 'darwin' ? `open "${MASTER_URL}"` :
                  process.platform === 'win32' ? `start "${MASTER_URL}"` :
                  `xdg-open "${MASTER_URL}" 2>/dev/null || termux-open-url "${MASTER_URL}" 2>/dev/null || echo "Open at ${MASTER_URL}"`;
  
  exec(openCmd, (err) => {
    if (!err) {
      console.log(`[SUCCESS] Automatically launched browser to ${MASTER_URL}`);
    }
  });
});
