const http = require("http");
const next = require("next");
const { Server } = require("socket.io");
const fs = require("fs");
const path = require("path");

const dev = process.env.NODE_ENV !== "production";
const app = next({ dev, turbopack: false });
const handle = app.getRequestHandler();

const DATA_DIR = path.join(process.cwd(), "data");
const DATA_FILE = path.join(DATA_DIR, "orders.json");
fs.mkdirSync(DATA_DIR, { recursive: true });

function loadOrders() {
  try { return JSON.parse(fs.readFileSync(DATA_FILE, "utf8")); }
  catch { return []; }
}
function saveOrders(orders) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(orders, null, 2));
}

const orders = loadOrders();

app.prepare().then(() => {
  const httpServer = http.createServer((req, res) => handle(req, res));
  const io = new Server(httpServer, { cors: { origin: "*" } });

  io.on("connection", (socket) => {
    socket.emit("orders:snapshot", orders);

    socket.on("order:create", (payload, ack) => {
      const order = {
        id: crypto.randomUUID(),
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        status: "new",
        customer: {
          name: String(payload?.customer?.name || "").trim(),
          phone: String(payload?.customer?.phone || "").trim(),
          email: String(payload?.customer?.email || "").trim()
        },
        request: String(payload?.request || "").trim(),
        gps: payload?.gps?.consented
          ? { consented: true, lat: Number(payload.gps.lat), lng: Number(payload.gps.lng), accuracy: Number(payload.gps.accuracy || 0) }
          : { consented: false },
        notes: String(payload?.notes || "").trim()
      };

      if (!order.customer.name || !order.customer.phone || !order.request) {
        return ack?.({ ok: false, error: "Name, phone, and request are required." });
      }

      orders.unshift(order);
      saveOrders(orders);
      io.emit("order:created", order);
      ack?.({ ok: true, order });
    });

    socket.on("order:update", ({ id, status, runnerNote, eta }) => {
      const order = orders.find(o => o.id === id);
      if (!order) return;
      const allowed = ["new", "accepted", "shopping", "ready", "out_for_delivery", "completed", "cancelled"];
      if (!allowed.includes(status)) return;
      order.status = status;
      order.updatedAt = new Date().toISOString();
      if (runnerNote !== undefined) order.runnerNote = String(runnerNote);
      if (eta !== undefined) order.eta = String(eta);
      saveOrders(orders);
      io.emit("order:updated", order);
    });

    socket.on("order:location", ({ id, lat, lng, accuracy }) => {
      const order = orders.find(o => o.id === id);
      if (!order || !order.gps?.consented) return;
      order.runnerLocation = { lat: Number(lat), lng: Number(lng), accuracy: Number(accuracy || 0), at: new Date().toISOString() };
      order.updatedAt = new Date().toISOString();
      saveOrders(orders);
      io.emit("order:location", { id, location: order.runnerLocation });
    });
  });

  httpServer.listen(process.env.PORT || 3000, "0.0.0.0", () => {
    console.log(`Request Runner listening on http://0.0.0.0:${process.env.PORT || 3000}`);
  });
});