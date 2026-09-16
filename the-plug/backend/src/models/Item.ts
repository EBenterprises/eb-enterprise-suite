import { Schema, model, Document } from 'mongoose';

export interface IItem extends Document {
  name: string;
  category: string;
  quantity: number;
  price: number;
  status: 'In Stock' | 'Low Stock' | 'Out of Stock';
  supplier: string;
  updatedAt: Date;
}

const ItemSchema = new Schema<IItem>({
  name: { type: String, required: true },
  category: { type: String, required: true },
  quantity: { type: Number, required: true, default: 0 },
  price: { type: Number, required: true, default: 0 },
  status: { type: String, enum: ['In Stock', 'Low Stock', 'Out of Stock'], default: 'In Stock' },
  supplier: { type: String, required: true }
}, { timestamps: true });

export const Item = model<IItem>('Item', ItemSchema);
