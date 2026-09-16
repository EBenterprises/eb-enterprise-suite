import { IUsersModuleAPI } from '../../users/api/users.service.interface';

export interface Message {
  id: string;
  senderId: string;
  channelId: string;
  content: string;
  timestamp: number;
}

export class ChatService {
  private messages: Message[] = [];

  constructor(private usersApi: IUsersModuleAPI) {}

  async createMessage(senderId: string, channelId: string, content: string): Promise<any> {
    const message: Message = {
      id: 'msg-' + Math.random().toString(36).substring(2, 9),
      senderId,
      channelId,
      content,
      timestamp: Date.now()
    };
    
    this.messages.push(message);
    return this.enrichMessageWithAuthor(message);
  }

  async enrichMessageWithAuthor(message: Message) {
    const author = await this.usersApi.getUserProfile(message.senderId);
    return {
      ...message,
      author: author ?? { id: message.senderId, username: 'Anonymous', avatarUrl: '' }
    };
  }

  async getChannelHistory(channelId: string) {
    const channelMsgs = this.messages.filter(m => m.channelId === channelId);
    const enriched = [];
    for (const msg of channelMsgs) {
      enriched.push(await this.enrichMessageWithAuthor(msg));
    }
    return enriched;
  }
}
