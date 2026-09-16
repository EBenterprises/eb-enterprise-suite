const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.send('<h1>EB Enterprises - Executive Spectrum Active</h1>');
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Test server running at http://0.0.0.0:${port}`);
});
