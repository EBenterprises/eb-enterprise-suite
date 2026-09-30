#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd "$HOME/sales-tracker"

echo "=== INSPECTING SERVER HTML STRUCTURE ==="
python3 - <<'PY'
from pathlib import Path

server_file = Path("instances/v1/server.js")
content = server_file.read_text()

# Print out a snippet containing HTML tags to see what tag exists
for line in content.splitlines():
    if '<body' in line.lower() or '<div' in line.lower() or '<form' in line.lower() or 'html' in line.lower():
        print(line[:100])
PY

echo "=== PATCHING WITH ROBUST CONTAINER INJECTION ==="
python3 - <<'PY'
from pathlib import Path
import re

dual_fields_html = '''
    <div class="location-capture-group" style="background: #f8f9fa; padding: 15px; border-radius: 6px; border: 1px solid #dee2e6; margin-bottom: 15px; font-family: sans-serif;">
        <h4 style="margin-top: 0; margin-bottom: 10px; color: #333;">Location Details</h4>
        
        <!-- Field 1: Auto-Captured Coordinates -->
        <div style="margin-bottom: 12px;">
            <label style="display: block; font-weight: bold; margin-bottom: 4px; font-size: 14px;">Coordinates (Auto-Captured):</label>
            <div style="display: flex; gap: 8px;">
                <input type="text" id="coordinates" name="coordinates" placeholder="Fetching GPS coordinates..." style="flex: 1; padding: 8px; box-sizing: border-box; border: 1px solid #ccc; border-radius: 4px;" readonly>
                <button type="button" onclick="captureCoordinates()" style="padding: 8px 12px; background: #28a745; color: white; border: none; cursor: pointer; border-radius: 4px; font-weight: bold;">Recapture</button>
            </div>
        </div>

        <!-- Field 2: Manual Nearest Landmark Input -->
        <div style="margin-bottom: 5px;">
            <label style="display: block; font-weight: bold; margin-bottom: 4px; font-size: 14px;">Nearest Landmark / Location Name:</label>
            <input type="text" id="nearestLandmark" name="nearest_landmark" placeholder="e.g., Beside Central Park fountain, Near 4th & Main" style="width: 100%; padding: 8px; box-sizing: border-box; border: 1px solid #ccc; border-radius: 4px;">
        </div>
    </div>

    <script>
    function captureCoordinates() {
        const coordInput = document.getElementById('coordinates');
        if (!navigator.geolocation) {
            coordInput.value = 'Geolocation not supported';
            return;
        }
        coordInput.value = 'Acquiring GPS fix...';
        navigator.geolocation.getCurrentPosition(
            (position) => {
                const lat = position.coords.latitude.toFixed(6);
                const lon = position.coords.longitude.toFixed(6);
                coordInput.value = `${lat}, ${lon}`;
            },
            (error) => {
                coordInput.value = 'GPS Error: ' + error.message;
            },
            { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 }
        );
    }

    window.addEventListener('DOMContentLoaded', () => {
        captureCoordinates();
    });
    </script>
'''

for v in ["v1", "v2", "v3", "v4", "v5"]:
    server_file = Path(f"instances/{v}/server.js")
    if not server_file.exists():
        continue

    content = server_file.read_text()

    # Clean previous injection attempts if any
    content = re.sub(r'<div class="location-capture-group".*?<\/script>', '', content, flags=re.DOTALL)

    # Try injecting right after a form tag (case insensitive) or body tag
    inserted = False
    for pattern in [r'(<form[^>]*>)', r'(<body[^>]*>)']:
        match = re.search(pattern, content, re.IGNORECASE)
        if match:
            tag = match.group(1)
            content = content.replace(tag, tag + '\n' + dual_fields_html, 1)
            server_file.write_text(content)
            print(f"Successfully injected dual fields into {v} using {tag}")
            inserted = True
            break
    
    if not inserted:
        print(f"ERROR: Could not find suitable insertion tag in {v}")
PY

echo "=== RESTARTING CLUSTER ==="
./start_cluster.sh
