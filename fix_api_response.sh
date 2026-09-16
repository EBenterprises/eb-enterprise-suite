#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - JSON Response & API Routing Fixer
# ==============================================================================
set -e

echo "[+] Fixing frontend fetch handlers and API routing..."

cat << 'SRV_EOF' > server.js
const express = require('express');
const mongoose = require('mongoose');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_spot_reservation';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryReservations = [
    { email: 'operator@eb.enterprise', spotNumber: 1, createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => {
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

// Explicit API Routes BEFORE static middleware
app.post('/api/reserve', async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ error: 'Email address is required to reserve your spot.' });
        }

        let spotNumber;
        const timestamp = new Date().toISOString();

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

        console.log("\n==================================================");
        console.log(`[ALERT] NEW LEAD CAPTURED! [Spot #${spotNumber}]`);
        console.log(`[TIMESTAMP]: ${timestamp}`);
        console.log(`[EMAIL]: ${email}`);
        console.log("==================================================\n");

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

// Static files middleware after API routes
app.use(express.static(path.join(__dirname, 'public')));

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`[+] Spot reservation server active and listening on port ${PORT}`);
});
SRV_EOF

echo "[+] Updating public/index.html with strict content-type verification..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="capture-container">
        <div class="badge">Limited Allocation</div>
        <h1 class="headline">EB Enterprises</h1>
        <p class="subheadline">Enter your email address to reserve your spot</p>

        <form id="reservation-form" class="capture-form">
            <div class="input-group">
                <input type="email" id="email" placeholder="Enter your email address..." required autocomplete="email">
            </div>
            <button type="submit" class="btn-capture">Reserve My Spot</button>
        </form>

        <div id="toast"></div>

        <div class="footer-note">
            EB Enterprises &bull; Zero Spam &bull; Sovereign Infrastructure
        </div>
    </div>

    <script>
        document.getElementById('reservation-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value.trim();
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!email) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Reserving Spot...';

            try {
                const res = await fetch('/api/reserve', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ email })
                });

                const contentType = res.headers.get("content-type");
                if (!contentType || !contentType.includes("application/json")) {
                    throw new Error("Received non-JSON response from server.");
                }

                const data = await res.json();

                toast.style.display = 'block';
                if (res.ok) {
                    toast.style.background = 'rgba(34, 197, 94, 0.15)';
                    toast.style.color = 'var(--success)';
                    toast.style.border = '1px solid var(--success)';
                    toast.textContent = data.message;
                    document.getElementById('reservation-form').reset();
                    submitBtn.textContent = 'Spot Reserved ✓';
                } else {
                    throw new Error(data.error || 'Reservation failed.');
                }
            } catch (err) {
                toast.style.display = 'block';
                toast.style.background = 'rgba(239, 68, 68, 0.15)';
                toast.style.color = 'var(--danger)';
                toast.style.border = '1px solid var(--danger)';
                toast.textContent = err.message;
                submitBtn.disabled = false;
                submitBtn.textContent = 'Reserve My Spot';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Restarting server instance..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_spot_reservation" nohup node server.js > server.log 2>&1 &
echo "[+] Server restarted. API routes prioritized before static file middleware."
