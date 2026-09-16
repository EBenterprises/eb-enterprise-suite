'use client';

import React, { useState } from 'react';

export default function SecureOpsCenter() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [passcode, setPasscode] = useState('');
  const [error, setError] = useState(false);

  const [orders, setOrders] = useState([
    { id: 'ORD-501', client: 'Okanagan Hub A', service: 'Same-Day Courier Dispatch', courier: 'Assigned (Unit 04)', status: 'In Transit', time: '11:10 AM' },
    { id: 'ORD-502', client: 'West Kelowna Depot', service: 'Bulk Freight Intake', courier: 'Pending Assignment', status: 'Queued', time: '10:55 AM' },
    { id: 'ORD-503', client: 'Retail Partner B', service: 'Express Document Run', courier: 'Completed (Unit 01)', status: 'Delivered', time: '09:40 AM' },
  ]);

  const [filter, setFilter] = useState('All');

  const handleLogin = (e) => {
    e.preventDefault();
    // Authorized administrative passcode gate
    if (passcode === 'EB2026' || passcode === 'admin') {
      setIsAuthenticated(true);
      setError(false);
    } else {
      setError(true);
    }
  };

  const updateOrderStatus = (id, newStatus) => {
    setOrders(prev => prev.map(o => o.id === id ? { ...o, status: newStatus } : o));
  };

  const filteredOrders = filter === 'All' ? orders : orders.filter(o => o.status === filter);

  if (!isAuthenticated) {
    return (
      <main style={{ minHeight: '100vh', background: '#0b0f19', color: '#e2e8f0', fontFamily: 'sans-serif', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}>
        <div style={{ width: '100%', maxWidth: '400px', background: '#1e293b', border: '1px solid #334155', borderRadius: '12px', padding: '2rem', boxShadow: '0 10px 25px rgba(0,0,0,0.5)' }}>
          <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
            <h1 style={{ color: '#38bdf8', fontSize: '1.5rem', margin: '0 0 0.5rem 0' }}>Restricted Access</h1>
            <p style={{ color: '#94a3b8', fontSize: '0.9rem', margin: 0 }}>EB Enterprises® Executive Back Office</p>
          </div>
          <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.85rem', color: '#cbd5e1', marginBottom: '0.5rem' }}>Administrative Passcode</label>
              <input
                type="password"
                value={passcode}
                onChange={(e) => setPasscode(e.target.value)}
                placeholder="Enter security key..."
                style={{ width: '100%', padding: '0.75rem', background: '#0f172a', border: '1px solid #334155', borderRadius: '6px', color: '#f8fafc', fontSize: '1rem', outline: 'none' }}
                autoFocus
              />
            </div>
            {error && <div style={{ color: '#f87171', fontSize: '0.85rem' }}>Invalid passcode. Access denied.</div>}
            <button
              type="submit"
              style={{ background: '#38bdf8', color: '#0b0f19', border: 'none', padding: '0.75rem', borderRadius: '6px', fontWeight: 'bold', fontSize: '1rem', cursor: 'pointer', transition: 'background 0.2s' }}
            >
              Authenticate
            </button>
          </form>
        </div>
      </main>
    );
  }

  return (
    <main style={{ minHeight: '100vh', background: '#0b0f19', color: '#e2e8f0', fontFamily: 'sans-serif', padding: '2rem' }}>
      {/* Header */}
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #1e293b', paddingBottom: '1rem', marginBottom: '2rem' }}>
        <div>
          <h1 style={{ color: '#38bdf8', fontSize: '1.8rem', margin: 0 }}>EB Enterprises® — Fulfillment & Operations Center</h1>
          <p style={{ color: '#94a3b8', margin: '0.25rem 0 0 0', fontSize: '0.95rem' }}>Active dispatch coordination, courier routing, and order execution management.</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
          <div style={{ background: '#1e293b', padding: '0.5rem 1rem', borderRadius: '6px', border: '1px solid #334155', fontSize: '0.85rem', color: '#facc15' }}>
            Dispatch Status: <span style={{ color: '#4ade80' }}>ACTIVE</span>
          </div>
          <button
            onClick={() => setIsAuthenticated(false)}
            style={{ background: 'transparent', border: '1px solid #ef4444', color: '#ef4444', padding: '0.5rem 1rem', borderRadius: '6px', cursor: 'pointer', fontSize: '0.85rem', fontWeight: 'bold' }}
          >
            Lock
          </button>
        </div>
      </header>

      {/* Metrics Bar */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem', marginBottom: '2rem' }}>
        <div style={{ background: '#1e293b', padding: '1.25rem', borderRadius: '8px', border: '1px solid #334155' }}>
          <div style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Active Dispatches</div>
          <div style={{ fontSize: '1.8rem', fontWeight: 'bold', color: '#f8fafc', marginTop: '0.25rem' }}>{orders.length}</div>
        </div>
        <div style={{ background: '#1e293b', padding: '1.25rem', borderRadius: '8px', border: '1px solid #334155' }}>
          <div style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Queued for Dispatch</div>
          <div style={{ fontSize: '1.8rem', fontWeight: 'bold', color: '#facc15', marginTop: '0.25rem' }}>
            {orders.filter(o => o.status === 'Queued').length}
          </div>
        </div>
        <div style={{ background: '#1e293b', padding: '1.25rem', borderRadius: '8px', border: '1px solid #334155' }}>
          <div style={{ color: '#94a3b8', fontSize: '0.85rem' }}>In Transit</div>
          <div style={{ fontSize: '1.8rem', fontWeight: 'bold', color: '#38bdf8', marginTop: '0.25rem' }}>
            {orders.filter(o => o.status === 'In Transit').length}
          </div>
        </div>
        <div style={{ background: '#1e293b', padding: '1.25rem', borderRadius: '8px', border: '1px solid #334155' }}>
          <div style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Delivered Today</div>
          <div style={{ fontSize: '1.8rem', fontWeight: 'bold', color: '#4ade80', marginTop: '0.25rem' }}>
            {orders.filter(o => o.status === 'Delivered').length}
          </div>
        </div>
      </div>

      {/* Filters */}
      <div style={{ display: 'flex', gap: '0.75rem', marginBottom: '1.5rem', alignItems: 'center' }}>
        <span style={{ fontSize: '0.9rem', color: '#94a3b8' }}>Filter Fulfillment:</span>
        {['All', 'Queued', 'In Transit', 'Delivered'].map(tab => (
          <button
            key={tab}
            onClick={() => setFilter(tab)}
            style={{
              background: filter === tab ? '#38bdf8' : '#1e293b',
              color: filter === tab ? '#0b0f19' : '#e2e8f0',
              border: '1px solid #334155',
              padding: '0.5rem 1rem',
              borderRadius: '6px',
              cursor: 'pointer',
              fontWeight: filter === tab ? 'bold' : 'normal',
              transition: 'all 0.2s'
            }}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Fulfillment Table */}
      <div style={{ background: '#1e293b', borderRadius: '8px', border: '1px solid #334155', overflow: 'hidden' }}>
        <div style={{ padding: '1rem 1.25rem', borderBottom: '1px solid #334155', fontWeight: 'bold', color: '#f8fafc' }}>
          Active Fulfillment & Courier Operations
        </div>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.95rem' }}>
            <thead>
              <tr style={{ background: '#0f172a', color: '#94a3b8', borderBottom: '1px solid #334155' }}>
                <th style={{ padding: '1rem' }}>Order / ID</th>
                <th style={{ padding: '1rem' }}>Destination / Client</th>
                <th style={{ padding: '1rem' }}>Service Type</th>
                <th style={{ padding: '1rem' }}>Courier / Unit</th>
                <th style={{ padding: '1rem' }}>Status</th>
                <th style={{ padding: '1rem', textAlign: 'right' }}>Fulfillment Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredOrders.map(ord => (
                <tr key={ord.id} style={{ borderBottom: '1px solid #334155' }}>
                  <td style={{ padding: '1rem', fontWeight: 'bold', color: '#38bdf8' }}>{ord.id}</td>
                  <td style={{ padding: '1rem' }}>{ord.client}</td>
                  <td style={{ padding: '1rem' }}>{ord.service}</td>
                  <td style={{ padding: '1rem', color: '#cbd5e1' }}>{ord.courier}</td>
                  <td style={{ padding: '1rem' }}>
                    <span style={{
                      padding: '0.25rem 0.75rem',
                      borderRadius: '999px',
                      fontSize: '0.8rem',
                      fontWeight: 'bold',
                      background: ord.status === 'Delivered' ? 'rgba(74, 222, 128, 0.15)' : ord.status === 'In Transit' ? 'rgba(56, 189, 248, 0.15)' : 'rgba(250, 204, 21, 0.15)',
                      color: ord.status === 'Delivered' ? '#4ade80' : ord.status === 'In Transit' ? '#38bdf8' : '#facc15',
                      border: `1px solid ${ord.status === 'Delivered' ? 'rgba(74, 222, 128, 0.3)' : ord.status === 'In Transit' ? 'rgba(56, 189, 248, 0.3)' : 'rgba(250, 204, 21, 0.3)'}`
                    }}>
                      {ord.status}
                    </span>
                  </td>
                  <td style={{ padding: '1rem', textAlign: 'right' }}>
                    {ord.status !== 'In Transit' && ord.status !== 'Delivered' && (
                      <button
                        onClick={() => updateOrderStatus(ord.id, 'In Transit')}
                        style={{ background: '#38bdf8', color: '#0b0f19', border: 'none', padding: '0.35rem 0.75rem', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold', marginRight: '0.5rem', fontSize: '0.85rem' }}
                      >
                        Dispatch
                      </button>
                    )}
                    {ord.status !== 'Delivered' && (
                      <button
                        onClick={() => updateOrderStatus(ord.id, 'Delivered')}
                        style={{ background: '#4ade80', color: '#0b0f19', border: 'none', padding: '0.35rem 0.75rem', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold', fontSize: '0.85rem' }}
                      >
                        Complete
                      </button>
                    )}
                  </td>
                </tr>
              ))}
              {filteredOrders.length === 0 && (
                <tr>
                  <td colSpan="6" style={{ padding: '2rem', textAlign: 'center', color: '#94a3b8' }}>
                    No fulfillment orders found matching the current filter.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </main>
  );
}
