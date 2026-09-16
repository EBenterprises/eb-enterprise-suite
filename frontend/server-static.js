import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
app.use(express.static(__dirname));
app.listen(8080, () => console.log('Client UI hosting on http://localhost:8080'));
