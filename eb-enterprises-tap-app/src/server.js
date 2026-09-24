const express = require('express');
const path = require('path');
const db = require('./models/db');

const app = express();
const PORT = 14001;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, '../public')));

// Frontend view with active user registration form
app.get('/', (req, res) => {
    const members = db.getMembers();
    res.send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>www.tap.eco — Live Affiliate & Community Platform</title>
            <style>
                :root { --bg: #010409; --card: #0d1117; --accent: #3fb950; --text: #f0f6fc; --muted: #8b949e; --border: #30363d; font-family: monospace; }
                body { background: var(--bg); color: var(--text); margin: 0; padding: 2rem; display: flex; justify-content: center; }
                .container { width: 100%; max-width: 700px; }
                .card { background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 2rem; margin-bottom: 1.5rem; }
                h1 { color: var(--accent); margin-top: 0; font-size: 1.8rem; }
                p { color: var(--muted); line-height: 1.5; }
                input, button { width: 100%; padding: 0.8rem; margin-top: 1rem; background: var(--bg); border: 1px solid var(--border); color: var(--text); border-radius: 6px; font-family: monospace; box-sizing: border-box; }
                button { background: var(--accent); color: #010409; font-weight: bold; cursor: pointer; text-transform: uppercase; }
                button:hover { background: #56d364; }
                ul { list-style: none; padding: 0; margin-top: 1rem; }
                li { background: var(--bg); border: 1px solid var(--border); padding: 0.6rem 1rem; border-radius: 4px; margin-bottom: 0.5rem; display: flex; justify-content: space-between; font-size: 0.85rem; }
                .badge { color: var(--accent); }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="card">
                    <h1>www.tap.eco</h1>
                    <p>Live affiliate network onboarding platform. Register your email below to instantly join the active node network managed under EB Enterprises®.</p>
                    <form action="/api/register" method="POST">
                        <input type="email" name="email" placeholder="Enter your email address..." required>
                        <button type="submit">Join Affiliate Network</button>
                    </form>
                </div>
                <div class="card">
                    <h3>Active Network Members (${members.length})</h3>
                    <ul>
                        ${members.map(m => `<li><span>${m.email}</span> <span class="badge">[${m.role}]</span></li>`).join('')}
                    </ul>
                </div>
            </div>
        </body>
        </html>
    `);
});

// API endpoint for registration handling
app.post('/api/register', (req, res) => {
    const { email } = req.body;
    if (email) {
        db.addMember(email);
    }
    res.redirect('/');
});

app.get('/api/members', (req, res) => {
    res.json(db.getMembers());
});

app.listen(PORT, () => {
    console.log(`[LIVE] www.tap.eco fully operational at http://localhost:${PORT}`);
});
