import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

const API_BASE_URL = 'http://localhost:5000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

api.interceptors.request.use(async (config) => {
  const token = await AsyncStorage.getItem('userToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
}, (error) => {
  return Promise.reject(error);
});

export const loginUser = async (email, password) => {
  const response = await api.post('/auth/login', { email, password });
  if (response.data.token) {
    await AsyncStorage.setItem('userToken', response.data.token);
  }
  return response.data;
};

export const registerUser = async (email, password) => {
  const response = await api.post('/auth/register', { email, password });
  if (response.data.token) {
    await AsyncStorage.setItem('userToken', response.data.token);
  }
  return response.data;
};

export const logoutUser = async () => {
  await AsyncStorage.removeItem('userToken');
};

export const fetchItems = async () => {
  const response = await api.get('/items');
  return response.data.data;
};

export const createItem = async (name) => {
  const response = await api.post('/items', { name });
  return response.data.data;
};
