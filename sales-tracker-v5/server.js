const express = require('express');
const app = express();
const PORT = 3005;
app.use(express.static(path.join(__dirname, 'public')));
app.listen(PORT, () => console.log(`[v5 Analytics] Running on http://localhost:${PORT}`));
