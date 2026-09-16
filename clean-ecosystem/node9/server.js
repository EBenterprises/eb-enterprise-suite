const express = require('express'); const path = require('path'); const app = express();
app.use(express.static(path.join(__dirname)));
app.listen(3009, () => console.log('[Node 9 (Vault)] Active on port 3009'));
