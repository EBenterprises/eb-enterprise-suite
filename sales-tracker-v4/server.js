const express = require('express');
const app = express();
const PORT = 3004;
app.use(express.static(path.join(__dirname, 'public')));
app.listen(PORT, () => console.log(`[v4 Map Edition] Running on http://localhost:${PORT}`));
