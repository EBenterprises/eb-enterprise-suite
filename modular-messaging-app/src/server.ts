import { createServer } from 'http';
import { WebSocketServer, WebSocket } from 'ws';
import { UsersService } from './modules/users/internal/users.service';
import { ChatService } from './modules/chat/internal/chat.service';
import { NotificationsListener } from './modules/notifications/internal/notifications.listener';
import { InMemoryEventBus } from './core/event-bus';

const server = createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ status: 'healthy', architecture: 'modular-monolith' }));
});

const wss = new WebSocketServer({ server });

// Initialize Core & Modules
const eventBus = new InMemoryEventBus();
const usersModule = new UsersService();
const chatModule = new ChatService(usersModule);

// Wire Cross-Module Event Listeners
eventBus.subscribe('chat.message.created', (payload) => {
  NotificationsListener.handleMessageCreated(payload);
});

wss.on('connection', (ws: WebSocket) => {
  console.log('[WebSocket] Client connected');

  ws.on('message', async (data: string) => {
    try {
      const packet = JSON.parse(data);
      
      if (packet.action === 'send_message') {
        const { senderId, channelId, content } = packet.payload;
        const enrichedMessage = await chatModule.createMessage(senderId, channelId, content);

        // Publish internal decoupled event
        eventBus.publish('chat.message.created', {
          messageId: enrichedMessage.id,
          channelId,
          content
        });

        // Broadcast to all connected websocket clients
        wss.clients.forEach(client => {
          if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify({ event: 'new_message', data: enrichedMessage }));
          }
        });
      }
    } catch (err) {
      console.error('[WebSocket] Failed to process message packet:', err);
    }
  });

  ws.on('close', () => {
    console.log('[WebSocket] Client disconnected');
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Modular Monolithic Messaging App running on http://localhost:${PORT}`);
});
