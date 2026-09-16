.PHONY: help setup migrate dev-backend dev-admin dev-mobile test e2e docker-up docker-down clean

help:
@echo "Enterprise Operations Makefile"
@echo "  make setup        - Install dependencies across all modules"
@echo "  make migrate      - Run database migrations"
@echo "  make dev-backend  - Start backend server in development mode"
@echo "  make dev-admin    - Start admin web terminal"
@echo "  make dev-mobile   - Start Expo mobile client"
@echo "  make test         - Run automated integration tests"
@echo "  make e2e          - Run end-to-end telemetry verification suite"
@echo "  make docker-up    - Spin up full containerized stack via Docker Compose"
@echo "  make docker-down  - Tear down Docker containers"
@echo "  make clean        - Remove node_modules and build artifacts"

setup:
@echo "[Setup] Installing backend dependencies..."
cd enterprise-scale-app/backend && npm install
@echo "[Setup] Installing web admin dependencies..."
cd enterprise-scale-app/web-admin && npm install
@echo "[Setup] Installing mobile dependencies..."
cd enterprise-scale-app/mobile && npm install
@echo "[Setup] All enterprise modules successfully provisioned."

migrate:
cd enterprise-scale-app/backend && npm run migrate

dev-backend:
cd enterprise-scale-app/backend && npm start

dev-admin:
cd enterprise-scale-app/web-admin && npm run dev

dev-mobile:
cd enterprise-scale-app/mobile && npm start

e2e:
node enterprise-scale-app/scripts/e2e-test.js

docker-up:
cd enterprise-scale-app && docker-compose up --build -d

docker-down:
cd enterprise-scale-app && docker-compose down

clean:
rm -rf enterprise-scale-app/backend/node_modules \
       enterprise-scale-app/web-admin/node_modules \
       enterprise-scale-app/mobile/node_modules
@echo "[Clean] Workspace artifacts purged."
