#!/bin/bash

echo "🚀 Initializing Request Runner ($r$) Project Structure..."

# 1. Create directories
mkdir -p api-gateway backend/src/config backend/src/controllers backend/src/middleware backend/src/models backend/src/routes/v1 backend/src/services backend/src/sockets/handlers backend/src/utils backend/src/validators backend/tests/integration backend/tests/unit
mkdir -p frontend/src/api frontend/src/assets/styles frontend/src/components/common frontend/src/components/layout frontend/src/components/location frontend/src/components/orders frontend/src/components/runner frontend/src/context frontend/src/hooks frontend/src/pages frontend/src/router frontend/src/utils

# 2. Write docker-compose.yml
cat << 'DOCKER' > docker-compose.yml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    restart: always

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "5000:5000"
    environment:
      - PORT=5000
      - MONGO_URI=mongodb://mongo:27017/request-runner
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      - redis
    restart: always

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "80:80"
    depends_on:
      - backend
    restart: always
DOCKER

# 3. Write backend/src/services/order.service.js
cat << 'SERVICE' > backend/src/services/order.service.js
const Order = require('../models/order.model');

class OrderService {
  async createOrder(orderData) {
    const order = new Order(orderData);
    await order.save();
    return order;
  }

  async getOrders(filter = {}, sort = { createdAt: -1 }) {
    return await Order.find(filter).sort(sort).populate('requester', 'name email');
  }

  async updateOrderStatus(orderId, updateData) {
    return await Order.findByIdAndUpdate(orderId, updateData, { new: true })
      .populate('requester', 'name email');
  }
}

module.exports = new OrderService();
SERVICE

# 4. Write frontend/src/context/LocationContext.jsx
cat << 'CONTEXT' > frontend/src/context/LocationContext.jsx
import React, { createContext, useContext, useState } from 'react';

const LocationContext = createContext();

export function LocationProvider({ children }) {
  const [tempLocation, setTempLocation] = useState({ lat: null, lng: null, description: '' });
  const [isSharing, setIsSharing] = useState(false);

  const requestLiveGPS = () => {
    if (!navigator.geolocation) {
      alert('Geolocation is not supported by your browser');
      return;
    }
    setIsSharing(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setTempLocation({
          lat: position.coords.latitude,
          lng: position.coords.longitude,
          description: 'Active Live GPS Coordinate'
        });
        setIsSharing(false);
      },
      () => {
        alert('Unable to capture location.');
        setIsSharing(false);
      }
    );
  };

  return (
    <LocationContext.Provider value={{ tempLocation, setTempLocation, isSharing, requestLiveGPS }}>
      {children}
    </LocationContext.Provider>
  );
}

export const useLocation = () => useContext(LocationContext);
CONTEXT

echo "✅ All scaled directories and configuration files have been successfully generated!"
echo "Run 'docker-compose up --build' to boot the cluster."
