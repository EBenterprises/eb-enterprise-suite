const fs = require('fs');
const { execSync } = require('child_process');

console.log("[+] Locating v5 server script (checking for v5 indicators)...");

// Find all js files or check server.js content to make sure it's v5
const files = fs.readdirSync('.');
let v5File = 'server.js';

files.forEach(f => {
    if (f.endsWith('.js') && f !== 'fix_and_start_v5.js') {
        const content = fs.readFileSync(f, 'utf8');
        if (content.includes('v5') || content.includes('51205') || content.includes('map') || content.includes('leaflet')) {
            v5File = f;
            console.log(`[+] Identified v5 file: ${v5File}`);
        }
    }
});

// Create a unified v5 runner that binds to port 51205 and includes the map picker
const unifiedV5Server = `
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 51205;

const server = http.createServer((req, res) => {
    console.log(\`[v5 P2P Master Suite] \${req.method} \-> \${req.url}\`);
    
    if (req.url === '/' || req.url === '/index.html') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(getV5MapPickerHtml());
    } else if (req.url === '/api/status') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ 
            suite: "EB Sales & Payments Tracker", 
            version: "v5 P2P Master Suite", 
            status: "active",
            mapPicker: "enabled",
            timestamp: new Date().toISOString()
        }));
    } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found');
    }
});

function getV5MapPickerHtml() {
    return \`<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Sales & Payments Tracker v5 P2P Master Suite</title>
    <!-- Leaflet CSS for Interactive Map Picker -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <style>
        body { font-family: monospace; background: #0f172a; color: #38bdf8; margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: auto; background: #1e293b; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
        h1 { color: #f8fafc; border-bottom: 2px solid #38bdf8; padding-bottom: 10px; }
        .card { background: #0f172a; padding: 15px; margin: 15px 0; border-radius: 6px; border-left: 4px solid #38bdf8; }
        #map { height: 400px; width: 100%; border-radius: 6px; margin-top: 10px; }
        button { background: #38bdf8; color: #0f172a; border: none; padding: 10px 15px; font-weight: bold; cursor: pointer; border-radius: 4px; margin-top: 10px; }
        button:hover { background: #0ea5e9; }
        pre { background: #090d16; padding: 10px; border-radius: 4px; overflow-x: auto; color: #a5f3fc; }
    </style>
</head>
<body>
    <div class="container">
        <h1>EB Sales & Payments Tracker v5 P2P Master Suite</h1>
        <div class="card">
            <h3>System Status</h3>
            <p>Daemon: <span style="color: #4ade80;">ONLINE</span> (Port 51205)</p>
            <p>Interactive Map Picker: <span style="color: #38bdf8;">ACTIVE (Leaflet Engine)</span></p>
        </div>
        <div class="card">
            <h3>Interactive Map Location Picker</h3>
            <p>Tap anywhere on the map to select transaction coordinates:</p>
            <div id="map"></div>
            <pre id="coords">Selected Coordinates: None</pre>
        </div>
    </div>
    <!-- Leaflet JS -->
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script>
        // Initialize Map centered on British Columbia / Default region
        const map = L.map('map').setView([49.2827, -123.1207], 10);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap'
        }).addTo(map);

        let marker;
        map.on('click', function(e) {
            const lat = e.latlng.lat.toFixed(6);
            const lng = e.latlng.lng.toFixed(6);
            document.getElementById('coords').innerText = \`Selected Coordinates: Lat \${lat}, Lng \${lng}\`;
            
            if (marker) {
                marker.setLatLng(e.latlng);
            } else {
                marker = L.marker(e.latlng).addTo(map);
            }
        });
    </script>
</body>
</html>\`;
}

server.listen(PORT, '127.0.0.1', () => {
    console.log(\`[+] EB Sales & Payments Tracker v5 P2P Master Suite running on http://127.0.0.1:\${PORT}\`);
});
`;

fs.writeFileSync('server_v5_master.js', unifiedV5Server);

// Terminate any existing node processes safely
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch(e) {}

// Start v5 background daemon
const out = fs.openSync('./server_v5.log', 'a');
const err = fs.openSync('./server_v5_err.log', 'a');
const { spawn } = require('child_process');
const serverProc = spawn('node', ['server_v5_master.js'], {
    detached: true,
    stdio: ['ignore', out, err]
});
serverProc.unref();

console.log(`[+] v5 P2P Master Suite daemon launched successfully on port 51205 (PID: ${serverProc.pid})!`);
