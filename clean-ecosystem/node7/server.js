const express = require('express'); const sqlite3 = require('sqlite3').verbose(); const path = require('path'); const cors = require('cors');
const app = express(); app.use(express.urlencoded({ extended: true })); app.use(cors());
const db = new sqlite3.Database(path.join(__dirname, '../database_subscriptions.db'));
db.run(`CREATE TABLE IF NOT EXISTS subs (id INTEGER PRIMARY KEY AUTOINCREMENT, subscriber TEXT, plan TEXT)`);
app.post('/subscribe', (req, res) => {
    db.run(`INSERT INTO subs (subscriber, plan) VALUES (?, ?)`, [req.body.subscriber, req.body.plan], () => {
        res.redirect('http://localhost:3008/node8/');
    });
});
app.listen(3007, () => console.log('[Node 7] Active on port 3007'));
