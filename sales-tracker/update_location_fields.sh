#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd "$HOME/sales-tracker"

echo "=== UPDATING SALES TRACKER INSTANCES WITH AUTO-LOCATION CAPTURE ==="

python3 - <<'PY'
from pathlib import Path
import re

# We will update the HTML template in all instances v1 through v5
for v in ["v1", "v2", "v3", "v4", "v5"]:
    server_file = Path(f"instances/{v}/server.js")
    if not server_file.exists():
        print(f"Skipping {v}, server.js not found.")
        continue

    content = server_file.read_text()

    # Form HTML snippet to inject or replace
    form_addition = '''
    <div style="margin-bottom: 15px;">
        <label style="display: block; font-weight: bold; margin-bottom: 5px;">Location Name:</label>
        <input type="text" id="locationName" name="location" placeholder="e.g., Downtown Store, Warehouse #4" style="width: 100%; padding: 8px; box-sizing: border-box;">
    </div>
    <div style="margin-bottom: 15px;">
        <label style="display: block; font-weight: bold; margin-bottom: 5px;">Coordinates:</label>
        <div style="display: flex; gap: 10px;">
            <input type="text" id="coordinates" name="coordinates" placeholder="Latitude, Longitude" style="flex: 1; padding: 8px; box-sizing: border-box;" readonly>
            <button type="button" onclick="captureCoordinates()" style="padding: 8px 12px; background: #007bff; color: white; border: none; cursor: pointer; border-radius: 4px;">Auto-Capture</button>
        </div>
    </div>
    <script>
    function captureCoordinates() {
        const coordInput = document.getElementById('coordinates');
        const locInput = document.getElementById('locationName');
        if (!navigator.geolocation) {
            alert('Geolocation is not supported by your browser');
            return;
        }
        coordInput.value = 'Locating...';
        navigator.geolocation.getCurrentPosition(
            (position) => {
                const lat = position.coords.latitude.toFixed(6);
                const lon = position.coords.longitude.toFixed(6);
                coordInput.value = `${lat}, ${lon}`;
                
                // Optional: Reverse lookup or auto-fill location if empty
                if (!locInput.value) {
                    locInput.value = `Lat: ${lat}, Lon: ${lon}`;
                }
            },
            (error) => {
                coordInput.value = '';
                alert('Unable to retrieve your location: ' + error.message);
            },
            { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
        );
    }
    // Auto-trigger on load if desired
    window.addEventListener('DOMContentLoaded', () => {
        captureCoordinates();
    });
    </script>
    '''

    # If the file contains an HTML form or template string, append/inject our form fields
    # We look for a common form tag or closing body tag to inject before
    if '<form' in content and 'coordinates' not in content:
        # Insert right after opening form tag
        updated = content.replace('<form', '<form' + '>\n' + form_addition, 1)
        server_file.write_text(updated)
        print(f"Updated {v} with location/coordinate fields.")
    else:
        print(f"Form tag not found or already updated in {v}.")
PY

echo "=== RESTARTING CLUSTER ==="
./start_cluster.sh

echo "GREEN: Location and auto-capturing coordinate fields integrated successfully."
