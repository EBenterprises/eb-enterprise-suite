# Request Runner®

A mobile-first, real-time pickup/delivery request platform.

## Flow

1. Customer opens `/request`.
2. Customer enters contact information.
3. Customer types a natural-language request.
4. Customer may explicitly grant GPS permission.
5. The request is sent over Socket.IO to the operations server.
6. `/ops` receives it immediately.
7. Operations/runner changes status live.
8. Customer-facing apps can subscribe to the same events.

## Run

```bash
npm install
npm run dev
```

Open:
- http://localhost:3000 — landing page
- http://localhost:3000/request — mobile intake
- http://localhost:3000/ops — live operations console

For another phone on the same Wi-Fi, use the computer's LAN IP, e.g. `http://192.168.1.20:3000`.

## Production architecture

For production, replace the JSON file store with PostgreSQL and a shared realtime layer such as Redis/WebSocket infrastructure. Add authentication, role-based access, audit logs, encrypted secrets, rate limiting, request validation, payment handling, runner assignment, maps, push notifications, and a privacy/consent workflow.

GPS is opt-in in this starter and is only transmitted when the browser grants permission.
