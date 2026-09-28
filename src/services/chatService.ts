import AsyncStorage from '@react-native-async-storage/async-storage';

export interface MessagePayload {
  id: string;
  sender: string;
  recipient: string;
  text: string;
  timestamp: number;
}

const STORAGE_PREFIX = '@tapchat_msg_';

export const ChatService = {
  async saveMessage(chatId: string, message: MessagePayload): Promise<void> {
    try {
      const existing = await this.getMessages(chatId);
      const updated = [...existing, message];
      await AsyncStorage.setItem(`${STORAGE_PREFIX}${chatId}`, JSON.stringify(updated));
    } catch (error) {
      console.error('Failed to persist message:', error);
    }
  },

  async getMessages(chatId: string): Promise<MessagePayload[]> {
    try {
      const data = await AsyncStorage.getItem(`${STORAGE_PREFIX}${chatId}`);
      return data ? JSON.parse(data) : [];
    } catch (error) {
      console.error('Failed to retrieve messages:', error);
      return [];
    }
  },

  async clearChat(chatId: string): Promise<void> {
    try {
      await AsyncStorage.removeItem(`${STORAGE_PREFIX}${chatId}`);
    } catch (error) {
      console.error('Failed to clear chat history:', error);
    }
  }
};
