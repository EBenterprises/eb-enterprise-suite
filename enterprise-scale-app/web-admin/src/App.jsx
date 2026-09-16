import React, { useState, useEffect } from 'react';
import { io } from 'socket.io-client';
import ExecutiveDashboard from './components/ExecutiveDashboard';

export default function App() {
  const [token, setToken] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [logs, setLogs] = useState([]);
  const [stats, setStats] = useState({});
  const [socketStatus, setSocketStatus] = useState('Disconnected');

  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      const res = await fetch('http://localhost:5000/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });
      const data = await res.json();
      if (data.success) {
        setToken(data.token);
        setIsAuthenticated(true);
      } else {
        alert(data.error);
      }
    } catch (err) {
      alert('Connection error');
    }
  };

  useEffect(() => {
    if (!isAuthenticated) return;

    const fetchHealth = async () => {
      try {
        const res = await fetch('http://localhost:5000/health');
        const data = await res.json();
        setStats(data);
      } catch (err) {
        console.error('Health poll failed');
      }
    };

    fetchHealth();
    const healthInterval = setInterval(fetchHealth, 10000);
    return () => clearInterval(healthInterval);
  }, [isAuthenticated]);

  useEffect(() => {
    if (!isAuthenticated || !token) return;

    const socket = io('http://localhost:5000', {
      auth: { token }
    });

    socket.on('connect', () => {
      setSocketStatus('Connected & Secure');
      setLogs(prev => [`[${new Date().toLocaleTimeString()}] WebSocket Handshake Established`, ...prev]);
    });

    socket.on('disconnect', () => {
      setSocketStatus('Disconnected');
      setLogs(prev => [`[${new Date().toLocaleTimeString()}] WebSocket Link Lost`, ...prev]);
    });

    const pingInterval = setInterval(() => {
      socket.emit('client_ping', { pingId: Date.now() });
    }, 5000);

    socket.on('server_pong', (data) => {
      setLogs(prev => [`[${new Date().toLocaleTimeString()}] Pong received: ${JSON.stringify(data)}`, ...prev]);
    });

    return () => {
      clearInterval(pingInterval);
      socket.disconnect();
    };
  }, [isAuthenticated, token]);

  if (!isAuthenticated) {
    return (
      <div style={{ display: 'flex', height: '100vh', justifyContent: 'center', alignItems: 'center', background: '#0f172a' }}>
        <form onSubmit={handleLogin} style={{ background: '#1e293b', padding: 32, borderRadius: 12, width: 320, border: '1px solid #334155', boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.3)' }}>
          <h2 style={{ marginTop: 0, color: '#f8fafc', textAlign: 'center', fontSize: '22px' }}>Admin Terminal</h2>
          <input 
            type="email" 
            placeholder="Operator Email" 
            value={email} 
            onChange={e => setEmail(e.target.value)}
            style={{ width: '100%', padding: 12, marginBottom: 12, background: '#0f172a', border: '1px solid #475569', color: '#fff', borderRadius: 6, boxSizing: 'border-box' }}
          />
          <input 
            type="password" 
            placeholder="Password" 
            value={password} 
            onChange={e => setPassword(e.target.value)}
            style={{ width: '100%', padding: 12, marginBottom: 20, background: '#0f172a', border: '1px solid #475569', color: '#fff', borderRadius: 6, boxSizing: 'border-box' }}
          />
          <button type="submit" style={{ width: '100%', padding: 12, background: '#0ea5e9', border: 'none', color: '#fff', fontWeight: 'bold', borderRadius: 6, cursor: 'pointer' }}>Authenticate</button>
        </form>
      </div>
    );
  }

  return (
    <div style={{ padding: 40, maxWidth: 1100, margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <h1 style={{ margin: 0, fontSize: '26px', color: '#f8fafc' }}>Enterprise Operations Command</h1>
        <div style={{ background: '#1e293b', padding: '8px 16px', borderRadius: '8px', border: '1px solid #334155' }}>
          Socket Status: <span style={{ color: socketStatus.includes('Connected') ? '#22c55e' : '#ef4444', fontWeight: 'bold' }}>{socketStatus}</span>
        </div>
      </div>

      <ExecutiveDashboard stats={stats} logs={logs} />

      <h3 style={{ color: '#f8fafc', marginTop: '30px' }}>Live Telemetry Stream</h3>
      <div style={{ background: '#1e293b', border: '1px solid #334155', borderRadius: 8, padding: 16, height: 320, overflowY: 'auto', fontFamily: 'monospace', fontSize: '13px' }}>
        {logs.map((log, index) => (
          <div key={index} style={{ marginBottom: 6, color: '#38bdf8' }}>{log}</div>
        ))}
      </div>
    </div>
  );
}
