const http = require('http');
const PORT = process.env.PORT || 3103;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ status: 'online', tracker: 'EB Sales & Payments Tracker', port: PORT }));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[+] Sales Tracker instance active on port ${PORT}`);
});
