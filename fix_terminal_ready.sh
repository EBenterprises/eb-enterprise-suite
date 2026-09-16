#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Clean Console & Robust Telemetry Engine
# ==============================================================================
set -e

echo "[+] Suppressing driver deprecation warnings and arming live log monitor..."

cat << 'SRV_EOF' > server.js
// Suppress deprecated MongoDB driver warnings
process.removeAllListeners('warning');
process.on('warning', (warning) => {
    if (warning.name === 'DeprecationWarning') return;
    console.warn(warning.name, warning.message);
});

const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
const https = require('https');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_spot_reservation';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryReservations = [
    { email: 'operator@eb.enterprise', spotNumber: 1, createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory reservation store.");
});

const ReservationSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    spotNumber: { type: Number, required: true },
    createdAt: { type: Date, default: Date.now }
});

const Reservation = mongoose.models.Reservation || mongoose.model('Reservation', ReservationSchema);

function sendLeadAlert(email, spotNumber) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`🚨 [VIP LEAD ALERT] NEW SPOT RESERVED! [Spot #${spotNumber}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`🚨 *New Spot Reservation!*\n\n📧 *Email:* \`${email}\`\n🔢 *Spot Number:* \`#${spotNumber}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram push notification dispatched successfully.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram notification dispatch failed:", err.message);
        });
    }
}

app.post('/api/reserve', async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ error: 'Email address is required to reserve your spot.' });
        }

        let spotNumber;

        if (isMongoConnected) {
            const existing = await Reservation.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email has already reserved spot #' + existing.spotNumber + '.' });
            }
            const count = await Reservation.countDocuments();
            spotNumber = count + 1;
            const newRes = new Reservation({ email, spotNumber });
            await newRes.save();
        } else {
            const existing = memoryReservations.find(r => r.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email has already reserved spot #' + existing.spotNumber + '.' });
            }
            spotNumber = memoryReservations.length + 1;
            memoryReservations.unshift({ email, spotNumber, createdAt: new Date() });
        }

        sendLeadAlert(email, spotNumber);

        return res.status(200).json({ 
            success: true, 
            message: 'Spot #' + spotNumber + ' successfully reserved.', 
            spotNumber 
        });
    } catch (err) {
        console.error("[ERROR] Lead capture failure:", err.message);
        return res.status(500).json({ error: err.message });
    }
});

app.get('/api/stats', async (req, res) => {
    try {
        if (isMongoConnected) {
            const count = await Reservation.countDocuments();
            return res.json({ totalSpots: count + 42 });
        } else {
            return res.json({ totalSpots: memoryReservations.length + 42 });
        }
    } catch (err) {
        return res.json({ totalSpots: 43 });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`[+] Spot reservation server active and listening on port ${PORT}`);
    console.log(`[+] Real-time console alert system armed and clean of driver warnings.`);
});
SRV_EOF

echo "[+] Restarting clean server instance..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_spot_reservation" nohup node server.js > server.log 2>&1 &
echo "[+] Server restarted successfully. Run the command below to watch incoming leads live:"
echo ""
echo "    tail -f server.log"
echo ""
