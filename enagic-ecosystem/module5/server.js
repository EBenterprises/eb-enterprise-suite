const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const cors = require('cors');
const app = express();
app.use(express.urlencoded({ extended: true }));
app.use(cors());

const db = new sqlite3.Database(path.join(__dirname, '../database_distributors.db'));
db.run(`CREATE TABLE IF NOT EXISTS distributors (id INTEGER PRIMARY KEY AUTOINCREMENT, distributor_name TEXT, sponsor_id TEXT, status TEXT)`);

app.post('/activate', (req, res) => {
    const { distributor_name, sponsor_id } = req.body;
    db.run(`INSERT INTO distributors (distributor_name, sponsor_id, status) VALUES (?, ?, ?)`, [distributor_name, sponsor_id, 'Active 8-Point Node'], () => {
        res.send(`<div style="background:#0B0C10;color:#D4AF37;padding:50px;text-align:center;font-family:sans-serif;"><h1>Distributorship Successfully Activated!</h1><p>Welcome to the EB Enterprises® / Enagic® Global Distribution Network.</p><br><a href="http://localhost:3001" style="color:#008080;">Return to Ecosystem Start</a></div>`);
    });
});
app.listen(3005, () => console.log('[Module 5] Distributor Engine active on http://localhost:3005'));
