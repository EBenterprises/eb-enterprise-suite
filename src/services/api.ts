import AsyncStorage from '@react-native-async-storage/async-storage';

const STORAGE_KEY = '@app_data_cache';

export const ApiService = {
  async saveData(data: string): Promise<boolean> {
    try {
      await AsyncStorage.setItem(STORAGE_KEY, data);
      return true;
    } catch (error) {
      console.error('Failed to save data', error);
      return false;
    }
  },

  async getData(): Promise<string | null> {
    try {
      return await AsyncStorage.getItem(STORAGE_KEY);
    } catch (error) {
      console.error('Failed to load data', error);
      return null;
    }
  }
};
