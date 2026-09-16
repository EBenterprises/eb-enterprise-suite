#!/bin/bash
set -e

echo "[+] Adding copyright notice to application footer..."

python3 -c '
with open("public/index.html", "r") as f:
    html = f.read()

copyright_html = """
        <footer style="text-align: center; margin-top: 3rem; padding: 1.5rem 0; border-top: 1px solid var(--border-color); color: var(--text-muted); font-size: 0.85rem; font-family: monospace;">
            &copy; 2026 EB Enterprises / Easton Bodeux Inc. All rights reserved.
        </footer>
    </div>
"""

if "footer style" not in html:
    # Replace closing div of app-container
    html = html.replace("    </div>\n\n    <!-- Payment Modal -->", copyright_html + "\n    <!-- Payment Modal -->")
    with open("public/index.html", "w") as f:
        f.write(html)
    print("[+] Successfully injected copyright footer into index.html")
else:
    print("[+] Copyright footer already present.")
'

echo "[+] Restarting server..."
./run.sh
