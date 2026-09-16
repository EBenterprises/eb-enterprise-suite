const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const cors = require('cors');
const app = express();
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(cors());

const db = new sqlite3.Database(path.join(__dirname, '../database_leads.db'));
db.run(`CREATE TABLE IF NOT EXISTS leads (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT, phone TEXT)`);

app.post('/capture', (req, res) => {
    const { name, email, phone } = req.body;
    db.run(`INSERT INTO leads (name, email, phone) VALUES (?, ?, ?)`, [name, email, phone], () => {
        res.redirect('http://localhost:3002');
    });
});
app.listen(3001, () => console.log('[Module 1] Lead Capture active on http://localhost:3001'));
