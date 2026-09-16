import React, { useState } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, Alert } from 'react-native';
import { registerUser } from '../services/api';

export default function RegisterScreen({ onRegisterSuccess, onNavigateLogin }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const handleRegister = async () => {
    if (!email || !password) {
      Alert.alert('Validation Error', 'All fields are required.');
      return;
    }
    try {
      setLoading(true);
      await registerUser(email, password);
      onRegisterSuccess();
    } catch (error) {
      Alert.alert('Registration Failed', error.response?.data?.error || 'Could not provision account.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Provision Account</Text>
      <TextInput
        style={styles.input}
        placeholder="Corporate Email"
        placeholderTextColor="#666"
        autoCapitalize="none"
        keyboardType="email-address"
        value={email}
        onChangeText={setEmail}
      />
      <TextInput
        style={styles.input}
        placeholder="Security Password"
        placeholderTextColor="#666"
        secureTextEntry
        value={password}
        onChangeText={setPassword}
      />
      <TouchableOpacity style={styles.button} onPress={handleRegister} disabled={loading}>
        <Text style={styles.buttonText}>{loading ? 'Provisioning...' : 'Register Account'}</Text>
      </TouchableOpacity>
      <TouchableOpacity onPress={onNavigateLogin} style={styles.linkContainer}>
        <Text style={styles.linkText}>Existing operator? <Text style={styles.linkHighlight}>Sign In</Text></Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', backgroundColor: '#0f172a', paddingHorizontal: 24 },
  title: { fontSize: 28, fontWeight: 'bold', color: '#f8fafc', marginBottom: 32, textAlign: 'center' },
  input: { backgroundColor: '#1e293b', borderWidth: 1, borderColor: '#334155', borderRadius: 8, paddingHorizontal: 16, height: 52, fontSize: 16, color: '#f8fafc', marginBottom: 16 },
  button: { backgroundColor: '#0ea5e9', justifyContent: 'center', alignItems: 'center', borderRadius: 8, height: 52, marginTop: 8 },
  buttonText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
  linkContainer: { marginTop: 24, alignItems: 'center' },
  linkText: { color: '#94a3b8', fontSize: 14 },
  linkHighlight: { color: '#38bdf8', fontWeight: 'bold' }
});
