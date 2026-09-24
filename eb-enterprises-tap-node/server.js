const express = require('express');
const app = express();
const PORT = 13001;

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>www.tap.eco — EB Enterprises® Node</title>
        <style>
            body { background: #010409; color: #f0f6fc; font-family: monospace; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            .box { background: #0d1117; border: 1px solid #30363d; padding: 2rem; border-radius: 8px; text-align: center; }
            h1 { color: #ff7b72; margin-bottom: 1rem; }
            p { color: #8b949e; }
        </style>
    </head>
    <body>
        <div class="box">
            <h1>www.tap.eco Node Active</h1>
            <p>Port 13001 is online and communicating with the Omniverse.</p>
        </div>
    </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`[TAP-NODE] www.tap.eco active at http://localhost:${PORT}`);
});
