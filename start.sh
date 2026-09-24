#!/bin/bash
# Automatically locate plug-monolith or create it if missing
if [ -d "plug-monolith" ]; then
    cd plug-monolith
elif [ -d "../plug-monolith" ]; then
    cd ../plug-monolith
else
    echo "==> Directory plug-monolith not found. Creating and building monolithic server..."
    mkdir -p plug-monolith
    cd plug-monolith
    # Re-generate package.json and server files if needed
    cat << 'INNER_EOF' > package.json
{
  "name": "plug-monolith",
  "version": "1.0.0",
  "description": "All-in-one monolithic secure plug messenger",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "jsonwebtoken": "^9.0.2",
    "mongoose": "^8.3.1",
    "socket.io": "^4.7.5"
  }
}
INNER_EOF
    npm install
fi

echo "==> Entering $(pwd)"
if [ ! -d "node_modules" ]; then
    echo "==> Installing dependencies..."
    npm install
fi

echo "==> Starting monolithic server..."
npm start
