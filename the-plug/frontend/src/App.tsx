import React, { useState, useEffect } from 'react';
import { Package, Plus, Trash2, Edit2, TrendingUp, AlertTriangle, DollarSign, RefreshCw } from 'lucide-react';

interface Item {
  _id: string;
  name: string;
  category: string;
  quantity: number;
  price: number;
  status: 'In Stock' | 'Low Stock' | 'Out of Stock';
  supplier: string;
}

export default function App() {
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState({ name: '', category: '', quantity: 0, price: 0, supplier: '' });
  const [editingId, setEditingId] = useState<string | null>(null);

  const fetchItems = async () => {
    try {
      setLoading(true);
      const res = await fetch('/api/items');
      const data = await res.json();
      setItems(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchItems();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const status = form.quantity === 0 ? 'Out of Stock' : form.quantity < 5 ? 'Low Stock' : 'In Stock';
    const payload = { ...form, status };

    try {
      if (editingId) {
        await fetch(`/api/items/${editingId}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        setEditingId(null);
      } else {
        await fetch('/api/items', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
      }
      setForm({ name: '', category: '', quantity: 0, price: 0, supplier: '' });
      fetchItems();
    } catch (err) {
      console.error(err);
    }
  };

  const handleEdit = (item: Item) => {
    setForm({ name: item.name, category: item.category, quantity: item.quantity, price: item.price, supplier: item.supplier });
    setEditingId(item._id);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this asset?')) return;
    try {
      await fetch(`/api/items/${id}`, { method: 'DELETE' });
      fetchItems();
    } catch (err) {
      console.error(err);
    }
  };

  const totalValue = items.reduce((acc, item) => acc + (item.quantity * item.price), 0);
  const lowStockCount = items.filter(i => i.status === 'Low Stock' || i.status === 'Out of Stock').length;

  return (
    <div className="min-h-screen pb-12">
      <header className="border-b border-slate-800 bg-slate-900/50 backdrop-blur sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="bg-emerald-500/10 p-2.5 rounded-xl border border-emerald-500/20 text-emerald-400">
              <Package className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-xl font-bold tracking-tight text-white">THE PLUG</h1>
              <p className="text-xs text-slate-400">Inventory & Operations Command Center</p>
            </div>
          </div>
          <button onClick={fetchItems} className="flex items-center space-x-2 px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-sm font-medium transition">
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            <span>Sync</span>
          </button>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 mt-8 space-y-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-slate-900/40 border border-slate-800/80 rounded-2xl p-6">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-slate-400">Total Valuation</span>
              <div className="p-2 bg-emerald-500/10 text-emerald-400 rounded-lg"><DollarSign className="w-5 h-5" /></div>
            </div>
            <p className="text-3xl font-bold text-white mt-4">${totalValue.toLocaleString()}</p>
          </div>
          <div className="bg-slate-900/40 border border-slate-800/80 rounded-2xl p-6">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-slate-400">Active SKUs</span>
              <div className="p-2 bg-blue-500/10 text-blue-400 rounded-lg"><TrendingUp className="w-5 h-5" /></div>
            </div>
            <p className="text-3xl font-bold text-white mt-4">{items.length}</p>
          </div>
          <div className="bg-slate-900/40 border border-slate-800/80 rounded-2xl p-6">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-slate-400">Restock Alerts</span>
              <div className="p-2 bg-amber-500/10 text-amber-400 rounded-lg"><AlertTriangle className="w-5 h-5" /></div>
            </div>
            <p className="text-3xl font-bold text-white mt-4">{lowStockCount}</p>
          </div>
        </div>

        <div className="bg-slate-900/40 border border-slate-800/80 rounded-2xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4">{editingId ? 'Edit Inventory Asset' : 'Register New Asset'}</h2>
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-6 gap-4">
            <input 
              type="text" placeholder="Item Name" value={form.name} 
              onChange={e => setForm({...form, name: e.target.value})} required
              className="bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-emerald-500 text-white"
            />
            <input 
              type="text" placeholder="Category" value={form.category} 
              onChange={e => setForm({...form, category: e.target.value})} required
              className="bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-emerald-500 text-white"
            />
            <input 
              type="number" placeholder="Quantity" value={form.quantity} 
              onChange={e => setForm({...form, quantity: Number(e.target.value)})} required
              className="bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-emerald-500 text-white"
            />
            <input 
              type="number" placeholder="Price ($)" value={form.price} 
              onChange={e => setForm({...form, price: Number(e.target.value)})} required
              className="bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-emerald-500 text-white"
            />
            <input 
              type="text" placeholder="Supplier" value={form.supplier} 
              onChange={e => setForm({...form, supplier: e.target.value})} required
              className="bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-emerald-500 text-white"
            />
            <button type="submit" className="bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold rounded-xl px-4 py-2.5 text-sm transition flex items-center justify-center space-x-2">
              <Plus className="w-4 h-4" />
              <span>{editingId ? 'Update' : 'Add Item'}</span>
            </button>
          </form>
        </div>

        <div className="bg-slate-900/40 border border-slate-800/80 rounded-2xl overflow-hidden">
          <div className="p-6 border-b border-slate-800">
            <h2 className="text-lg font-semibold text-white">Inventory Directory</h2>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-800 text-slate-400 text-xs uppercase tracking-wider">
                  <th className="p-4">Item</th>
                  <th className="p-4">Category</th>
                  <th className="p-4">Quantity</th>
                  <th className="p-4">Price</th>
                  <th className="p-4">Status</th>
                  <th className="p-4">Supplier</th>
                  <th className="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60 text-sm">
                {loading ? (
                  <tr><td colSpan={7} className="p-6 text-center text-slate-500">Loading directory...</td></tr>
                ) : items.length === 0 ? (
                  <tr><td colSpan={7} className="p-6 text-center text-slate-500">No assets registered yet.</td></tr>
                ) : items.map((item) => (
                  <tr key={item._id} className="hover:bg-slate-900/80 transition">
                    <td className="p-4 font-medium text-white">{item.name}</td>
                    <td className="p-4 text-slate-400">{item.category}</td>
                    <td className="p-4 text-white font-mono">{item.quantity}</td>
                    <td className="p-4 text-white font-mono">${item.price.toFixed(2)}</td>
                    <td className="p-4">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${
                        item.status === 'In Stock' ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' :
                        item.status === 'Low Stock' ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20' :
                        'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                      }`}>
                        {item.status}
                      </span>
                    </td>
                    <td className="p-4 text-slate-400">{item.supplier}</td>
                    <td className="p-4 text-right space-x-2">
                      <button onClick={() => handleEdit(item)} className="p-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg transition"><Edit2 className="w-4 h-4" /></button>
                      <button onClick={() => handleDelete(item._id)} className="p-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 rounded-lg transition"><Trash2 className="w-4 h-4" /></button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}
