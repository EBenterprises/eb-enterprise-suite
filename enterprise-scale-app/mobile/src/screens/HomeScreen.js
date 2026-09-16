import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, FlatList, ActivityIndicator } from 'react-native';
import { fetchItems, createItem, logoutUser } from '../services/api';

export default function HomeScreen({ onLogout }) {
  const [items, setItems] = useState([]);
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    try {
      setLoading(true);
      const data = await fetchItems();
      setItems(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleAdd = async () => {
    if (!text.trim()) return;
    try {
      await createItem(text);
      setText('');
      loadData();
    } catch (e) {
      console.error(e);
    }
  };

  const handleLogoutPress = async () => {
    await logoutUser();
    onLogout();
  };

  return (
    <View style={styles.container}>
      <View style={styles.headerRow}>
        <Text style={styles.title}>Operator Dashboard</Text>
        <TouchableOpacity onPress={handleLogoutPress} style={styles.logoutButton}>
          <Text style={styles.logoutText}>Logout</Text>
        </TouchableOpacity>
      </View>
      
      <View style={styles.inputContainer}>
        <TextInput
          style={styles.input}
          placeholder="New system payload entry..."
          placeholderTextColor="#666"
          value={text}
          onChangeText={setText}
        />
        <TouchableOpacity style={styles.button} onPress={handleAdd}>
          <Text style={styles.buttonText}>Inject</Text>
        </TouchableOpacity>
      </View>

      {loading ? (
        <ActivityIndicator size="large" color="#0ea5e9" style={{ marginTop: 24 }} />
      ) : (
        <FlatList
          data={items}
          keyExtractor={(item) => item.id.toString()}
          renderItem={({ item }) => (
            <View style={styles.itemCard}>
              <Text style={styles.itemText}>{item.name}</Text>
              <Text style={styles.itemSubtext}>ID: {item.id} | Timestamp: {new Date(item.created_at).toLocaleTimeString()}</Text>
            </View>
          )}
          contentContainerStyle={styles.listContainer}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0f172a', paddingTop: 60, paddingHorizontal: 20 },
  headerRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 },
  title: { fontSize: 22, fontWeight: 'bold', color: '#f8fafc' },
  logoutButton: { backgroundColor: '#ef4444', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 6 },
  logoutText: { color: '#fff', fontWeight: 'bold', fontSize: 14 },
  inputContainer: { flexDirection: 'row', marginBottom: 20 },
  input: { flex: 1, backgroundColor: '#1e293b', borderWidth: 1, borderColor: '#334155', borderRadius: 8, paddingHorizontal: 15, height: 48, fontSize: 16, color: '#f8fafc' },
  button: { backgroundColor: '#0ea5e9', justifyContent: 'center', alignItems: 'center', paddingHorizontal: 20, borderRadius: 8, marginLeft: 10, height: 48 },
  buttonText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
  listContainer: { paddingBottom: 20 },
  itemCard: { backgroundColor: '#1e293b', padding: 16, borderRadius: 8, marginBottom: 12, borderWidth: 1, borderColor: '#334155' },
  itemText: { fontSize: 16, color: '#f8fafc', fontWeight: '500', marginBottom: 4 },
  itemSubtext: { fontSize: 12, color: '#94a3b8' }
});
