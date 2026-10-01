const express = require('express');
const app = express();
const PORT = 3003;
app.use(express.static(path.join(__dirname, 'public')));
app.listen(PORT, () => console.log(`[v3] Running on http://localhost:${PORT}`));
