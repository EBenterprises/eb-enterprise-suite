const express = require('express');
const path = require('path');
const app = express();
app.use(express.static(path.join(__dirname)));
app.listen(3002, () => console.log('[Module 2] Education Engine active on http://localhost:3002'));
