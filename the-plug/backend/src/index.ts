import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectDB } from './config/db';
import itemRoutes from './routes/itemRoutes';

dotenv.config();
connectDB();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

app.use('/api/items', itemRoutes);

app.get('/', (req, res) => {
  res.send('The Plug API is running...');
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
