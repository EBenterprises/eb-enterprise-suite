import { IUsersModuleAPI, UserDTO } from '../api/users.service.interface';

export class UsersService implements IUsersModuleAPI {
  private users: Map<string, UserDTO> = new Map([
    ['user-1', { id: 'user-1', username: 'Aiden Vance', avatarUrl: 'https://avatar.example.sh/aiden' }],
    ['user-2', { id: 'user-2', username: 'Kira Sterling', avatarUrl: 'https://avatar.example.sh/kira' }]
  ]);

  async getUserProfile(userId: string): Promise<UserDTO | null> {
    return this.users.get(userId) || null;
  }

  async getBatchUsers(userIds: string[]): Promise<Map<string, UserDTO>> {
    const result = new Map<string, UserDTO>();
    for (const id of userIds) {
      const user = this.users.get(id);
      if (user) result.set(id, user);
    }
    return result;
  }
}
