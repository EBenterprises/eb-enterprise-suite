#!/bin/bash
# TAPCHAT Unified Build & Execution Script

echo "🚀 Initializing TAPCHAT Monorepo..."
mkdir -p tapchat-monorepo/backend/src/services \
         tapchat-monorepo/mobile-app/src/app \
         tapchat-monorepo/packages/shared-types/src/models \
         tapchat-monorepo/packages/shared-types/src/events

cat << 'INNER_EOF' > tapchat-monorepo/packages/shared-types/src/events/socket-events.enum.ts
export enum SocketEvents {
  CONNECT = 'connection',
  DISCONNECT = 'disconnect',
  JOIN_ROOM = 'join_room',
  LEAVE_ROOM = 'leave_room',
  SEND_MESSAGE = 'send_message',
  RECEIVE_MESSAGE = 'receive_message',
  LOAD_HISTORY = 'load_history',
  ROOM_USERS = 'room_users',
  TYPING = 'typing',
  DISPLAY_TYPING = 'display_typing',
  SEND_PRIVATE_MESSAGE = 'send_private_message',
  RECEIVE_PRIVATE_MESSAGE = 'receive_private_message',
  GET_ONLINE_USERS = 'get_online_users',
  ONLINE_USERS_LIST = 'online_users_list'
}
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/packages/shared-types/src/models/message.model.ts
export type MessageType = 'user' | 'system' | 'private';

export interface IMessage {
  id: string;
  room?: string;
  author: string;
  recipientSocketId?: string;
  message: string;
  time: string;
  type: MessageType;
}

export interface IPrivateMessagePayload {
  recipientSocketId: string;
  senderName: string;
  message: string;
}
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/packages/shared-types/src/index.ts
export * from './models/message.model';
export * from './events/socket-events.enum';
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/packages/shared-types/package.json
{
  "name": "@tapchat/shared-types",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "devDependencies": {
    "typescript": "^5.4.2"
  }
}
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/backend/package.json
{
  "name": "tapchat-backend",
  "version": "1.0.0",
  "main": "dist/server.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/server.js",
    "dev": "ts-node-dev --respawn --transpile-only src/server.ts"
  },
  "dependencies": {
    "@tapchat/shared-types": "file:../packages/shared-types",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "socket.io": "^4.7.5"
  },
  "devDependencies": {
    "@types/cors": "^2.8.17",
    "@types/express": "^4.17.21",
    "@types/node": "^20.11.30",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.4.2"
  }
}
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/backend/tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
    "rootDir": "src",
    "outDir": "dist",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"]
}
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/backend/src/services/socket.service.ts
import { Server, Socket } from 'socket.io';
import { SocketEvents, IMessage, IPrivateMessagePayload } from '@tapchat/shared-types';

interface ConnectedUser {
  socketId: string;
  username: string;
  room?: string;
}

export class SocketService {
  private io: Server;
  private connectedUsers: Map<string, ConnectedUser> = new Map();

  constructor(io: Server) {
    this.io = io;
    this.initListeners();
  }

  private initListeners() {
    this.io.on(SocketEvents.CONNECT, (socket: Socket) => {
      console.log(`[Socket] Client connected: ${socket.id}`);

      socket.on(SocketEvents.JOIN_ROOM, ({ username, room }: { username: string; room: string }) => {
        socket.join(room);
        this.connectedUsers.set(socket.id, { socketId: socket.id, username, room });

        this.broadcastOnlineUsers();

        const joinMsg: IMessage = {
          id: Math.random().toString(36).substring(7),
          room,
          author: 'System',
          message: `${username} is now online.`,
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          type: 'system'
        };
        this.io.to(room).emit(SocketEvents.RECEIVE_MESSAGE, joinMsg);
      });

      socket.on(SocketEvents.SEND_MESSAGE, (payload: { room: string; author: string; message: string }) => {
        const { room, author, message } = payload;
        const msgData: IMessage = {
          id: Math.random().toString(36).substring(7),
          room,
          author,
          message,
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          type: 'user'
        };

        this.io.to(room).emit(SocketEvents.RECEIVE_MESSAGE, msgData);
      });

      socket.on(SocketEvents.SEND_PRIVATE_MESSAGE, (payload: IPrivateMessagePayload) => {
        const sender = this.connectedUsers.get(socket.id);
        if (!sender) return;

        const privateMsg: IMessage = {
          id: Math.random().toString(36).substring(7),
          author: sender.username,
          recipientSocketId: payload.recipientSocketId,
          message: payload.message,
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          type: 'private'
        };

        this.io.to(payload.recipientSocketId).emit(SocketEvents.RECEIVE_PRIVATE_MESSAGE, privateMsg);
        socket.emit(SocketEvents.RECEIVE_PRIVATE_MESSAGE, privateMsg);
      });

      socket.on(SocketEvents.DISCONNECT, () => {
        console.log(`[Socket] Client disconnected: ${socket.id}`);
        this.connectedUsers.delete(socket.id);
        this.broadcastOnlineUsers();
      });
    });
  }

  private broadcastOnlineUsers() {
    const userList = Array.from(this.connectedUsers.values());
    this.io.emit(SocketEvents.ONLINE_USERS_LIST, userList);
  }
}
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/backend/src/server.ts
import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import dotenv from 'dotenv';
import { SocketService } from './services/socket.service';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] }
});

new SocketService(io);

const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
  console.log(`🚀 TAPCHAT Backend Engine active on port ${PORT}`);
});
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/mobile-app/package.json
{
  "name": "tapchat-mobile",
  "version": "1.0.0",
  "main": "expo-router/entry",
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web",
    "build:android": "npx eas build --platform android",
    "build:ios": "npx eas build --platform ios",
    "build:web": "npx expo export",
    "desktop:windows": "npx electron-builder --win",
    "desktop:mac": "npx electron-builder --mac",
    "desktop:linux": "npx electron-builder --linux"
  },
  "dependencies": {
    "@expo/vector-icons": "^14.0.0",
    "expo": "~51.0.0",
    "expo-router": "~3.5.0",
    "expo-status-bar": "~1.12.1",
    "react": "18.2.0",
    "react-native": "0.74.1",
    "react-native-safe-area-context": "4.10.5",
    "react-native-screens": "~3.31.1",
    "socket.io-client": "^4.7.5"
  },
  "devDependencies": {
    "@babel/core": "^7.20.0",
    "@types/react": "~18.2.45",
    "electron-builder": "^24.13.3",
    "typescript": "~5.1.3"
  },
  "private": true
}
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/mobile-app/app.json
{
  "expo": {
    "name": "TAPCHAT",
    "slug": "tapchat",
    "version": "1.0.0",
    "orientation": "portrait",
    "scheme": "tapchat",
    "userInterfaceStyle": "dark",
    "splash": {
      "resizeMode": "contain",
      "backgroundColor": "#090d16"
    },
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.ebenterprises.tapchat"
    },
    "android": {
      "package": "com.ebenterprises.tapchat",
      "adaptiveIcon": {
        "backgroundColor": "#090d16"
      }
    },
    "web": {
      "bundler": "metro"
    },
    "plugins": [
      "expo-router"
    ]
  }
}
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/mobile-app/eas.json
{
  "cli": {
    "version": ">= 10.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {
      "android": {
        "buildType": "app-bundle"
      },
      "ios": {
        "simulator": false
      }
    }
  },
  "submit": {
    "production": {}
  }
}
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/mobile-app/tsconfig.json
{
  "extends": "expo/tsconfig.base"
}
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/mobile-app/src/app/_layout.tsx
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';

export default function RootLayout() {
  return (
    <>
      <StatusBar style="light" />
      <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: '#090d16' } }}>
        <Stack.Screen name="index" />
        <Stack.Screen name="chat" />
      </Stack>
    </>
  );
}
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/mobile-app/src/app/index.tsx
import React, { useState } from 'react';
import { 
  StyleSheet, 
  Text, 
  View, 
  TextInput, 
  TouchableOpacity, 
  KeyboardAvoidingView, 
  Platform,
  Alert
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function LoginScreen() {
  const [username, setUsername] = useState('');
  const [room, setRoom] = useState('');
  const router = useRouter();

  const handleJoin = () => {
    if (!username.trim() || !room.trim()) {
      Alert.alert('Validation Error', 'Please enter both your name and a room identifier.');
      return;
    }
    router.push({
      pathname: '/chat',
      params: { username: username.trim(), room: room.trim().toLowerCase() }
    });
  };

  return (
    <KeyboardAvoidingView 
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'} 
      style={styles.container}
    >
      <View style={styles.card}>
        <View style={styles.iconContainer}>
          <Ionicons name="chatbubbles" size={48} color="#6366f1" />
        </View>
        <Text style={styles.title}>TAPCHAT</Text>
        <Text style={styles.subtitle}>Secure real-time global channels & DMs</Text>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>Display Name</Text>
          <TextInput
            style={styles.input}
            placeholder="e.g. Alex Morgan"
            placeholderTextColor="#64748b"
            value={username}
            onChangeText={setUsername}
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>Chat Room ID</Text>
          <TextInput
            style={styles.input}
            placeholder="e.g. core-eng"
            placeholderTextColor="#64748b"
            autoCapitalize="none"
            value={room}
            onChangeText={setRoom}
          />
        </View>

        <TouchableOpacity style={styles.button} onPress={handleJoin} activeOpacity={0.8}>
          <Text style={styles.buttonText}>Join TAPCHAT</Text>
          <Ionicons name="arrow-forward" size={20} color="#fff" style={styles.btnIcon} />
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#090d16', justifyContent: 'center', padding: 24 },
  card: { backgroundColor: '#111827', borderRadius: 20, padding: 24, borderWidth: 1, borderColor: '#1f2937' },
  iconContainer: { width: 80, height: 80, borderRadius: 20, backgroundColor: '#1e1b4b', justifyContent: 'center', alignItems: 'center', marginBottom: 20 },
  title: { fontSize: 26, fontWeight: '700', color: '#f8fafc', marginBottom: 6 },
  subtitle: { fontSize: 14, color: '#94a3b8', marginBottom: 24 },
  inputGroup: { marginBottom: 16 },
  label: { fontSize: 13, fontWeight: '600', color: '#cbd5e1', marginBottom: 8 },
  input: { height: 52, backgroundColor: '#0b0f19', borderWidth: 1, borderColor: '#374151', borderRadius: 12, paddingHorizontal: 16, color: '#fff', fontSize: 15 },
  button: { height: 52, backgroundColor: '#6366f1', borderRadius: 12, flexDirection: 'row', justifyContent: 'center', alignItems: 'center', marginTop: 12 },
  buttonText: { color: '#fff', fontSize: 16, fontWeight: '600' },
  btnIcon: { marginLeft: 8 }
});
INNER_EOF

cat << 'INNER_EOF' > tapchat-monorepo/mobile-app/src/app/chat.tsx
import React, { useState, useEffect, useRef } from 'react';
import { 
  StyleSheet, 
  Text, 
  View, 
  TextInput, 
  TouchableOpacity, 
  FlatList, 
  KeyboardAvoidingView, 
  Platform,
  SafeAreaView,
  Modal
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import io, { Socket } from 'socket.io-client';

const SOCKET_URL = 'http://localhost:3001';

interface Message {
  id: string;
  author: string;
  recipientSocketId?: string;
  message: string;
  time: string;
  type?: 'user' | 'system' | 'private';
}

interface OnlineUser {
  socketId: string;
  username: string;
  room?: string;
}

export default function ChatScreen() {
  const { username, room } = useLocalSearchParams<{ username: string; room: string }>();
  const router = useRouter();
  
  const [messages, setMessages] = useState<Message[]>([]);
  const [currentMessage, setCurrentMessage] = useState('');
  const [onlineUsers, setOnlineUsers] = useState<OnlineUser[]>([]);
  const [selectedRecipient, setSelectedRecipient] = useState<OnlineUser | null>(null);
  const [showUserModal, setShowUserModal] = useState(false);

  const socketRef = useRef<Socket | null>(null);
  const flatListRef = useRef<FlatList>(null);

  useEffect(() => {
    const socket = io(SOCKET_URL);
    socketRef.current = socket;

    socket.emit('join_room', { username, room });

    socket.on('receive_message', (data: Message) => {
      setMessages((prev) => [...prev, data]);
    });

    socket.on('receive_private_message', (data: Message) => {
      setMessages((prev) => [...prev, data]);
    });

    socket.on('online_users_list', (users: OnlineUser[]) => {
      setOnlineUsers(users.filter(u => u.username !== username));
    });

    return () => {
      socket.disconnect();
    };
  }, [username, room]);

  const sendMessage = () => {
    if (!currentMessage.trim() || !socketRef.current) return;

    if (selectedRecipient) {
      socketRef.current.emit('send_private_message', {
        recipientSocketId: selectedRecipient.socketId,
        senderName: username,
        message: currentMessage.trim()
      });
    } else {
      socketRef.current.emit('send_message', {
        room,
        author: username,
        message: currentMessage.trim()
      });
    }

    setCurrentMessage('');
  };

  const displayedMessages = messages.filter(msg => {
    if (msg.type === 'private') {
      return (
        (msg.author === username && msg.recipientSocketId === selectedRecipient?.socketId) ||
        (msg.author === selectedRecipient?.username && msg.recipientSocketId === socketRef.current?.id)
      );
    }
    return !selectedRecipient && (msg.room === room || msg.type === 'system');
  });

  return (
    <SafeAreaView style={styles.safeArea}>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.container}>
        
        <View style={styles.header}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
            <Ionicons name="chevron-back" size={24} color="#fff" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.headerInfo} onPress={() => setShowUserModal(true)}>
            <Text style={styles.roomTitle}>
              {selectedRecipient ? `DM: @${selectedRecipient.username}` : `TAPCHAT #${room}`}
            </Text>
            <Text style={styles.onlineCount}>
              {selectedRecipient ? 'Tap to switch channel' : `${onlineUsers.length + 1} online • Tap for DMs`}
            </Text>
          </TouchableOpacity>
          {selectedRecipient && (
            <TouchableOpacity onPress={() => setSelectedRecipient(null)} style={styles.clearDmButton}>
              <Text style={styles.clearDmText}>Exit DM</Text>
            </TouchableOpacity>
          )}
        </View>

        <FlatList
          ref={flatListRef}
          data={displayedMessages}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.messageList}
          onContentSizeChange={() => flatListRef.current?.scrollToEnd({ animated: true })}
          renderItem={({ item }) => {
            const isMe = item.author === username;
            const isPrivate = item.type === 'private';

            return (
              <View style={[styles.bubbleWrapper, isMe ? styles.myBubbleWrapper : styles.otherBubbleWrapper]}>
                {!isMe && <Text style={styles.authorLabel}>{item.author}</Text>}
                <View style={[styles.messageBubble, isMe ? styles.myBubble : styles.otherBubble, isPrivate && styles.privateBubble]}>
                  {isPrivate && <Text style={styles.privateTag}>[Direct Message]</Text>}
                  <Text style={[styles.messageText, isMe ? styles.myMessageText : styles.otherMessageText]}>
                    {item.message}
                  </Text>
                  <Text style={[styles.timeText, isMe ? styles.myTimeText : styles.otherTimeText]}>
                    {item.time}
                  </Text>
                </View>
              </View>
            );
          }}
        />

        <View style={styles.footer}>
          <TextInput
            style={styles.input}
            placeholder={selectedRecipient ? `Message @${selectedRecipient.username}...` : "Type a public message..."}
            placeholderTextColor="#64748b"
            value={currentMessage}
            onChangeText={setCurrentMessage}
            multiline
          />
          <TouchableOpacity style={styles.sendButton} onPress={sendMessage} activeOpacity={0.8}>
            <Ionicons name="send" size={18} color="#fff" />
          </TouchableOpacity>
        </View>

        <Modal visible={showUserModal} animationType="slide" transparent={true}>
          <View style={styles.modalOverlay}>
            <View style={styles.modalContent}>
              <Text style={styles.modalTitle}>Select User for Direct Message</Text>
              
              <TouchableOpacity 
                style={[styles.userRow, !selectedRecipient && styles.selectedUserRow]}
                onPress={() => { setSelectedRecipient(null); setShowUserModal(false); }}
              >
                <Ionicons name="globe-outline" size={20} color="#6366f1" />
                <Text style={styles.modalUserText}>Return to Room #{room}</Text>
              </TouchableOpacity>

              <FlatList
                data={onlineUsers}
                keyExtractor={(item) => item.socketId}
                renderItem={({ item }) => (
                  <TouchableOpacity 
                    style={[styles.userRow, selectedRecipient?.socketId === item.socketId && styles.selectedUserRow]}
                    onPress={() => { setSelectedRecipient(item); setShowUserModal(false); }}
                  >
                    <Ionicons name="person-circle-outline" size={20} color="#10b981" />
                    <Text style={styles.modalUserText}>{item.username}</Text>
                  </TouchableOpacity>
                )}
              />

              <TouchableOpacity style={styles.closeModalBtn} onPress={() => setShowUserModal(false)}>
                <Text style={styles.closeModalText}>Close</Text>
              </TouchableOpacity>
            </View>
          </View>
        </Modal>

      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: '#090d16' },
  container: { flex: 1 },
  header: { height: 64, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, borderBottomWidth: 1, borderBottomColor: '#1f2937', backgroundColor: '#0b0f19' },
  backButton: { marginRight: 12, padding: 4 },
  headerInfo: { flex: 1 },
  roomTitle: { fontSize: 16, fontWeight: '700', color: '#f8fafc' },
  onlineCount: { fontSize: 12, color: '#10b981', marginTop: 2 },
  clearDmButton: { backgroundColor: '#374151', paddingHorizontal: 10, paddingVertical: 6, borderRadius: 6 },
  clearDmText: { color: '#fff', fontSize: 12, fontWeight: '600' },
  messageList: { padding: 16, paddingBottom: 24 },
  bubbleWrapper: { marginVertical: 6, maxWidth: '80%' },
  myBubbleWrapper: { alignSelf: 'flex-end' },
  otherBubbleWrapper: { alignSelf: 'flex-start' },
  authorLabel: { fontSize: 11, color: '#94a3b8', marginBottom: 4, marginLeft: 4, fontWeight: '600' },
  messageBubble: { padding: 12, borderRadius: 16 },
  myBubble: { backgroundColor: '#6366f1', borderBottomRightRadius: 4 },
  otherBubble: { backgroundColor: '#1e293b', borderBottomLeftRadius: 4 },
  privateBubble: { backgroundColor: '#7c3aed' },
  privateTag: { fontSize: 10, color: '#ddd6fe', fontWeight: 'bold', marginBottom: 2 },
  messageText: { fontSize: 15, lineHeight: 20 },
  myMessageText: { color: '#fff' },
  otherMessageText: { color: '#f1f5f9' },
  timeText: { fontSize: 10, marginTop: 4, alignSelf: 'flex-end' },
  myTimeText: { color: '#c7d2fe' },
  otherTimeText: { color: '#64748b' },
  footer: { flexDirection: 'row', padding: 12, backgroundColor: '#0b0f19', borderTopWidth: 1, borderTopColor: '#1f2937', alignItems: 'center' },
  input: { flex: 1, minHeight: 44, maxHeight: 100, backgroundColor: '#111827', borderWidth: 1, borderColor: '#374151', borderRadius: 22, paddingHorizontal: 16, paddingTop: 10, paddingBottom: 10, color: '#fff', fontSize: 15 },
  sendButton: { width: 44, height: 44, backgroundColor: '#6366f1', borderRadius: 22, justifyContent: 'center', alignItems: 'center', marginLeft: 8 },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.7)', justifyContent: 'center', padding: 20 },
  modalContent: { backgroundColor: '#111827', borderRadius: 16, padding: 20, maxHeight: '60%', borderWidth: 1, borderColor: '#374151' },
  modalTitle: { fontSize: 18, fontWeight: 'bold', color: '#fff', marginBottom: 16 },
  userRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: '#1f2937' },
  selectedUserRow: { backgroundColor: '#1e1b4b', borderRadius: 8, paddingHorizontal: 8 },
  modalUserText: { color: '#f8fafc', fontSize: 16, marginLeft: 12 },
  closeModalBtn: { marginTop: 16, backgroundColor: '#374151', padding: 12, borderRadius: 8, alignItems: 'center' },
  closeModalText: { color: '#fff', fontWeight: '600' }
});
INNER_EOF

echo "📦 Installing Shared Types..."
cd tapchat-monorepo/packages/shared-types && npm install

echo "📦 Installing Backend Dependencies & Building..."
cd ../../backend && npm install && npm run build

echo "📦 Installing Mobile/Cross-Platform App Dependencies..."
cd ../mobile-app && npm install

echo "🎉 TAPCHAT Monorepo compilation complete!"
echo "To start the backend server:"
echo "  cd tapchat-monorepo/backend && node dist/server.js"
echo "To start the cross-platform app:"
echo "  cd tapchat-monorepo/mobile-app && npx expo start"
