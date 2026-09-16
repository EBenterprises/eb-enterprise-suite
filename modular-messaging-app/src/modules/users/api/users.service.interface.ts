export interface UserDTO {
  id: string;
  username: string;
  avatarUrl: string;
}

export interface IUsersModuleAPI {
  getUserProfile(userId: string): Promise<UserDTO | null>;
  getBatchUsers(userIds: string[]): Promise<Map<string, UserDTO>>;
}
