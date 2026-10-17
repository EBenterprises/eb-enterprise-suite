const http = require('http');
const fs = require('fs');

const PORT = 51201;

const server = http.createServer((req, res) => {
    console.log(`[v5 Master Suite] ${req.method} -> ${req.url}`);
    
    if (req.url === '/' || req.url === '/index.html') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(`<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enterprise P2P Master Suite v5</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <style>
        body { font-family: monospace; background: #0b0f19; color: #38bdf8; margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: auto; background: #111827; padding: 20px; border-radius: 8px; border: 1px solid #1f2937; }
        h1 { color: #f8fafc; border-bottom: 2px solid #38bdf8; padding-bottom: 10px; }
        .card { background: #1f2937; padding: 15px; margin: 15px 0; border-radius: 6px; border-left: 4px solid #38bdf8; }
        #map { height: 400px; width: 100%; border-radius: 6px; margin-top: 10px; }
        pre { background: #030712; padding: 10px; border-radius: 4px; color: #a5f3fc; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Enterprise P2P Master Suite v5</h1>
        <div class="card">
            <h3>System Status</h3>
            <p>Status: <span style="color: #34d399; font-weight: bold;">ONLINE (Port 51201)</span></p>
            <p>Interactive Map Picker: <span style="color: #38bdf8;">ACTIVE</span></p>
        </div>
        <div class="card">
            <h3>Interactive Map Location Picker</h3>
            <p>Tap anywhere on the map to select coordinates:</p>
            <div id="map"></div>
            <pre id="coords">Selected Coordinates: None</pre>
        </div>
    </div>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script>
        const map = L.map('map').setView([49.2827, -123.1207], 11);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap'
        }).addTo(map);

        let marker;
        map.on('click', function(e) {
            const lat = e.latlng.lat.toFixed(6);
            const lng = e.latlng.lng.toFixed(6);
            document.getElementById('coords').innerText = 'Selected Coordinates: Lat ' + lat + ', Lng ' + lng;
            if (marker) {
                marker.setLatLng(e.latlng);
            } else {
                marker = L.marker(e.latlng).addTo(map);
            }
        });
    </script>
</body>
</html>`);
    } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found');
    }
});

server.listen(PORT, '127.0.0.1', () => {
    console.log(`[+] Enterprise P2P Master Suite v5 running live on http://127.0.0.1:${PORT}`);
});
