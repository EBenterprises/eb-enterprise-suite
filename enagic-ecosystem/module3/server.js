const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const cors = require('cors');
const app = express();
app.use(express.urlencoded({ extended: true }));
app.use(cors());

const db = new sqlite3.Database(path.join(__dirname, '../database_bookings.db'));
db.run(`CREATE TABLE IF NOT EXISTS bookings (id INTEGER PRIMARY KEY AUTOINCREMENT, client_name TEXT, consult_date TEXT, consult_time TEXT)`);

app.post('/book', (req, res) => {
    const { client_name, consult_date, consult_time } = req.body;
    db.run(`INSERT INTO bookings (client_name, consult_date, consult_time) VALUES (?, ?, ?)`, [client_name, consult_date, consult_time], () => {
        res.redirect('http://localhost:3004');
    });
});
app.listen(3003, () => console.log('[Module 3] Consultation active on http://localhost:3003'));
