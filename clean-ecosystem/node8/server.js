const express = require('express'); const sqlite3 = require('sqlite3').verbose(); const path = require('path'); const cors = require('cors');
const app = express(); app.use(express.urlencoded({ extended: true })); app.use(cors());
const db = new sqlite3.Database(path.join(__dirname, '../database_routes.db'));
db.run(`CREATE TABLE IF NOT EXISTS routes (id INTEGER PRIMARY KEY AUTOINCREMENT, alias_domain TEXT, target_port TEXT)`);
app.post('/route', (req, res) => {
    db.run(`INSERT INTO routes (alias_domain, target_port) VALUES (?, ?)`, [req.body.alias_domain, req.body.target_port], () => {
        res.redirect('http://localhost:3009/node9/');
    });
});
app.listen(3008, () => console.log('[Node 8] Active on port 3008'));
