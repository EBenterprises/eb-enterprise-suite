const express = require('express');
const path = require('path');
const db = require('./models/db');

const app = express();
const PORT = process.env.PORT || 14002;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, '../public')));

app.get('/', (req, res) => {
    const registry = db.getRegistry();
    res.send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>EB Enterprises — Full-Stack Command Center</title>
            <style>
                :root { --bg: #0d1117; --card: #161b22; --accent: #238636; --text: #c9d1d9; --muted: #8b949e; --border: #30363d; font-family: monospace; }
                body { background: var(--bg); color: var(--text); margin: 0; padding: 2rem; display: flex; justify-content: center; }
                .container { width: 100%; max-width: 800px; }
                .card { background: var(--card); border: 1px solid var(--border); border-radius: 6px; padding: 1.5rem; margin-bottom: 1rem; }
                h1 { color: #58a6ff; margin-top: 0; }
                ul { list-style: none; padding: 0; }
                li { background: var(--bg); border: 1px solid var(--border); padding: 0.75rem; border-radius: 4px; margin-top: 0.5rem; display: flex; justify-content: space-between; }
                .badge { color: var(--accent); font-weight: bold; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="card">
                    <h1>EB Enterprises Command Center</h1>
                    <p>Automated Full-Stack Node & Affiliate Infrastructure</p>
                </div>
                <div class="card">
                    <h3>Registered Ecosystem Nodes</h3>
                    <ul>
                        ${registry.nodes.map(n => `<li><span><strong>${n.name}</strong> (${n.type})</span> <span class="badge">[${n.status}]</span></li>`).join('')}
                    </ul>
                </div>
            </div>
        </body>
        </html>
    `);
});

app.listen(PORT, () => {
    console.log(`[EB Enterprises] Command center running on port ${PORT}`);
});
