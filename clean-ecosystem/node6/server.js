const express = require('express'); const sqlite3 = require('sqlite3').verbose(); const path = require('path'); const cors = require('cors');
const app = express(); app.use(express.urlencoded({ extended: true })); app.use(cors());
const db = new sqlite3.Database(path.join(__dirname, '../database_traffic.db'));
db.run(`CREATE TABLE IF NOT EXISTS traffic (id INTEGER PRIMARY KEY AUTOINCREMENT, campaign_title TEXT, keywords TEXT)`);
app.post('/traffic', (req, res) => {
    db.run(`INSERT INTO traffic (campaign_title, keywords) VALUES (?, ?)`, [req.body.campaign_title, req.body.keywords], () => {
        res.redirect('http://localhost:3007/node7/');
    });
});
app.listen(3006, () => console.log('[Node 6] Active on port 3006'));
