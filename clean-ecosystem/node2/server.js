const express = require('express'); const path = require('path'); const app = express();
app.use(express.static(path.join(__dirname)));
app.listen(3002, () => console.log('[Node 2] Active on port 3002'));
