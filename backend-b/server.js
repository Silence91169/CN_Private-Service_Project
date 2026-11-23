"use strict";
const http = require("http");
const backend = "B";
const port = Number(process.env.PORT || 3002);
const host = process.env.HOST || "0.0.0.0";

function sendJson(res, statusCode, body) {
  const payload = JSON.stringify(body);
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(payload),
    "Cache-Control": "no-store",
    "X-Backend": backend,
  });
  res.end(payload);
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || "localhost"}`);
  if (req.method !== "GET" && req.method !== "HEAD") {
    res.setHeader("Allow", "GET, HEAD");
    sendJson(res, 405, { error: "Method Not Allowed", backend });
    return;
  }
  const body = url.pathname === "/healthz"
    ? { backend, status: "ok" }
    : url.pathname === "/api/status"
      ? { backend, status: "ok", timestamp: new Date().toISOString() }
      : url.pathname === "/"
        ? { message: "CN Project Backend B", backend }
        : null;
  if (!body) {
    sendJson(res, 404, { error: "Not Found", backend });
    return;
  }
  if (req.method === "HEAD") {
    res.writeHead(200, { "Cache-Control": "no-store", "X-Backend": backend });
    res.end();
    return;
  }
  sendJson(res, 200, body);
});

server.requestTimeout = 10000;
server.headersTimeout = 5000;
server.keepAliveTimeout = 5000;
server.listen(port, host, () => console.log(`BACKEND ${backend} RUNNING on ${host}:${port}`));

function shutdown(signal) {
  console.log(`${signal} received; closing Backend ${backend}`);
  server.close((error) => process.exit(error ? 1 : 0));
  setTimeout(() => process.exit(1), 5000).unref();
}
process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));
