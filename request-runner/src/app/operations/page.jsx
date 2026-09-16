import React from 'react';

export default function OperationsPage() {
  return (
    <main style={{ padding: '2rem', background: '#0b0f19', color: '#e2e8f0', minHeight: '100vh', fontFamily: 'sans-serif' }}>
      <h1 style={{ color: '#38bdf8', borderBottom: '1px solid #1e293b', paddingBottom: '0.5rem' }}>EB Enterprises - Operations Center</h1>
      <p style={{ marginTop: '1rem', color: '#94a3b8' }}>Live system monitoring, workspace synchronization, and automated build pipelines.</p>
      
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.5rem', marginTop: '2rem' }}>
        <div style={{ background: '#1e293b', padding: '1.5rem', borderRadius: '8px', border: '1px solid #334155' }}>
          <h3 style={{ color: '#facc15', marginBottom: '0.5rem' }}>Repository Status</h3>
          <p style={{ fontSize: '0.9rem', color: '#cbd5e1' }}>Branch: master</p>
          <p style={{ fontSize: '0.9rem', color: '#cbd5e1' }}>Tracking: 100% Synchronized</p>
        </div>

        <div style={{ background: '#1e293b', padding: '1.5rem', borderRadius: '8px', border: '1px solid #334155' }}>
          <h3 style={{ color: '#facc15', marginBottom: '0.5rem' }}>Server Health</h3>
          <p style={{ fontSize: '0.9rem', color: '#cbd5e1' }}>Port: 3000 (Active)</p>
          <p style={{ fontSize: '0.9rem', color: '#cbd5e1' }}>Environment: Production</p>
        </div>

        <div style={{ background: '#1e293b', padding: '1.5rem', borderRadius: '8px', border: '1px solid #334155' }}>
          <h3 style={{ color: '#facc15', marginBottom: '0.5rem' }}>Automation Pipeline</h3>
          <p style={{ fontSize: '0.9rem', color: '#cbd5e1' }}>Heredoc Deploy: Enabled</p>
          <p style={{ fontSize: '0.9rem', color: '#cbd5e1' }}>Auto-Commit & Push: Active</p>
        </div>
      </div>
    </main>
  );
}
