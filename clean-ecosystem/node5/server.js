const express = require('express'); const sqlite3 = require('sqlite3').verbose(); const path = require('path'); const cors = require('cors');
const app = express(); app.use(express.urlencoded({ extended: true })); app.use(cors());
const db = new sqlite3.Database(path.join(__dirname, '../database_partners.db'));
db.run(`CREATE TABLE IF NOT EXISTS partners (id INTEGER PRIMARY KEY AUTOINCREMENT, partner_name TEXT, sponsor_id TEXT, status TEXT)`);
app.post('/partner', (req, res) => {
    db.run(`INSERT INTO partners (partner_name, sponsor_id, status) VALUES (?, ?, ?)`, [req.body.partner_name, req.body.sponsor_id, 'Active Partner'], () => {
        res.redirect('http://localhost:3006/node6/');
    });
});
app.listen(3005, () => console.log('[Node 5] Active on port 3005'));
