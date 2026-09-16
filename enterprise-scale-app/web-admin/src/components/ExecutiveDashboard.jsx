import React from 'react';

export default function ExecutiveDashboard({ stats, logs }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '20px', marginBottom: '24px' }}>
      <div style={{ background: '#1e293b', border: '1px solid #334155', borderRadius: '10px', padding: '20px', borderLeft: '4px solid #0ea5e9' }}>
        <h4 style={{ margin: '0 0 10px 0', color: '#94a3b8', fontSize: '14px', textTransform: 'uppercase' }}>System Uptime</h4>
        <p style={{ margin: 0, fontSize: '28px', fontWeight: 'bold', color: '#f8fafc' }}>{stats.uptime ? `${Math.floor(stats.uptime)}s` : 'Initializing...'}</p>
      </div>
      <div style={{ background: '#1e293b', border: '1px solid #334155', borderRadius: '10px', padding: '20px', borderLeft: '4px solid #22c55e' }}>
        <h4 style={{ margin: '0 0 10px 0', color: '#94a3b8', fontSize: '14px', textTransform: 'uppercase' }}>Database Status</h4>
        <p style={{ margin: 0, fontSize: '28px', fontWeight: 'bold', color: '#22c55e' }}>{stats.database || 'Connecting...'}</p>
      </div>
      <div style={{ background: '#1e293b', border: '1px solid #334155', borderRadius: '10px', padding: '20px', borderLeft: '4px solid #f59e0b' }}>
        <h4 style={{ margin: '0 0 10px 0', color: '#94a3b8', fontSize: '14px', textTransform: 'uppercase' }}>Telemetry Events</h4>
        <p style={{ margin: 0, fontSize: '28px', fontWeight: 'bold', color: '#f8fafc' }}>{logs.length}</p>
      </div>
    </div>
  );
}
