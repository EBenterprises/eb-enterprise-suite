import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, ScrollView, SafeAreaView } from 'react-native';
import { io } from 'socket.io-client';

export default function App() {
  const [token, setToken] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [socketStatus, setSocketStatus] = useState('Disconnected');
  const [logs, setLogs] = useState([]);

  const handleLogin = async () => {
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
        alert(data.error || 'Authentication failed');
      }
    } catch (err) {
      alert('Network connection error');
    }
  };

  useEffect(() => {
    if (!isAuthenticated || !token) return;

    const socket = io('http://localhost:5000', {
      auth: { token }
    });

    socket.on('connect', () => {
      setSocketStatus('Connected & Secure');
      setLogs(prev => [`[${new Date().toLocaleTimeString()}] Mobile Socket Link Established`, ...prev]);
    });

    socket.on('disconnect', () => {
      setSocketStatus('Disconnected');
      setLogs(prev => [`[${new Date().toLocaleTimeString()}] Mobile Socket Link Lost`, ...prev]);
    });

    const interval = setInterval(() => {
      socket.emit('client_ping', { source: 'mobile_client', timestamp: Date.now() });
    }, 5000);

    socket.on('server_pong', (data) => {
      setLogs(prev => [`[${new Date().toLocaleTimeString()}] Pong: ${JSON.stringify(data)}`, ...prev]);
    });

    return () => {
      clearInterval(interval);
      socket.disconnect();
    };
  }, [isAuthenticated, token]);

  if (!isAuthenticated) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.card}>
          <Text style={styles.title}>Enterprise Mobile</Text>
          <TextInput
            style={styles.input}
            placeholder="Operator Email"
            placeholderTextColor="#64748b"
            value={email}
            onChangeText={setEmail}
            autoCapitalize="none"
          />
          <TextInput
            style={styles.input}
            placeholder="Password"
            placeholderTextColor="#64748b"
            value={password}
            onChangeText={setPassword}
            secureTextEntry
          />
          <TouchableOpacity style={styles.button} onPress={handleLogin}>
            <Text style={styles.buttonText}>Authenticate Node</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Enterprise Operations</Text>
        <Text style={styles.statusText}>Status: <Text style={{ color: socketStatus.includes('Connected') ? '#22c55e' : '#ef4444' }}>{socketStatus}</Text></Text>
      </View>
      <Text style={styles.subHeader}>Live Telemetry Stream</Text>
      <ScrollView style={styles.logContainer}>
        {logs.map((log, index) => (
          <Text key={index} style={styles.logText}>{log}</Text>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0f172a', padding: 20, justifyContent: 'center' },
  card: { backgroundColor: '#1e293b', padding: 24, borderRadius: 12, borderWidth: 1, borderColor: '#334155' },
  title: { fontSize: 24, fontWeight: 'bold', color: '#f8fafc', marginBottom: 20, textAlign: 'center' },
  input: { backgroundColor: '#0f172a', borderWidth: 1, borderColor: '#475569', color: '#fff', padding: 12, borderRadius: 6, marginBottom: 12 },
  button: { backgroundColor: '#0ea5e9', padding: 14, borderRadius: 6, alignItems: 'center', marginTop: 8 },
  buttonText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
  header: { marginBottom: 20 },
  headerTitle: { fontSize: 22, fontWeight: 'bold', color: '#f8fafc' },
  statusText: { color: '#94a3b8', fontSize: 14, marginTop: 4 },
  subHeader: { fontSize: 16, fontWeight: 'bold', color: '#38bdf8', marginBottom: 10 },
  logContainer: { backgroundColor: '#1e293b', borderWidth: 1, borderColor: '#334155', borderRadius: 8, padding: 12, height: 400 },
  logText: { color: '#38bdf8', fontFamily: 'monospace', fontSize: 12, marginBottom: 6 }
});
