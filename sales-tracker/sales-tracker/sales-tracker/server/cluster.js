const createApp = require('./app');
const http = require('http');

const PORT = process.env.PORT || 3000;
const app = createApp();
const server = http.createServer(app);

server.listen(PORT, () => {
  console.log(`-> Deployed instance on port ${PORT} (PID: ${process.pid})`);
});
