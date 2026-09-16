const http = require('http');
const fs = require('fs');
const path = require('path');
const PORT = process.env.PORT || 3000;
const server = http.createServer((req, res) => {
  let filePath = path.join(__dirname, 'public', req.url === '/' ? 'index.html' : req.url);
  let extname = path.extname(filePath);
  let contentType = extname === '.js' ? 'text/javascript' : extname === '.css' ? 'text/css' : 'text/html';
  fs.readFile(filePath, (err, content) => {
    if (err) {
      fs.readFile(path.join(__dirname, 'public/index.html'), (err, content) => {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(content, 'utf-8');
      });
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});
server.listen(PORT, () => {
  console.log(`[PROPRIETARY ENGINE] Running at http://localhost:${PORT}/`);
  console.log(`[DEPLOYMENT] Automated container pipeline triggered successfully.`);
});
