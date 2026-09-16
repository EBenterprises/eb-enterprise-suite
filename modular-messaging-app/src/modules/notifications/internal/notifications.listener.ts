export class NotificationsListener {
  static handleMessageCreated(payload: { messageId: string; channelId: string; content: string }) {
    console.log(`[NotificationsModule] Dispatching push notification for message ${payload.messageId} in channel ${payload.channelId}: "${payload.content}"`);
  }
}
