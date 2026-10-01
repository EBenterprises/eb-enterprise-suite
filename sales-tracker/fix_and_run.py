import os

# Let's inspect or create a working single/multi server runner that listens correctly
server_code = """const http = require('http');
const PORT = process.env.PORT || 3100;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ status: 'online', tracker: 'EB Sales & Payments Tracker', port: PORT }));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[+] Sales Tracker instance active on port ${PORT}`);
});
"""

# Write to a central or multi-version structure if needed, or update server.js files
for d in ['v1', 'v2', 'v3', 'v4', 'v5']:
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, 'server.js'), 'w') as f:
        f.write(server_code.replace('3100', str(3100 + ['v1','v2','v3','v4','v5'].index(d))))

print("[+] Generated fresh server files for v1-v5.")
