import { createServer } from "node:http";
import next from "next";

const port = Number(process.env.PORT || 3000);
const hostname = process.env.HOST || "127.0.0.1";
const dev = process.env.NODE_ENV !== "production";

const app = next({
  dev,
  hostname,
  port
});

const handle = app.getRequestHandler();

await app.prepare();

createServer((req, res) => {
  handle(req, res);
}).listen(port, hostname, () => {
  console.log(`Tabs® → http://${hostname}:${port}`);
});
