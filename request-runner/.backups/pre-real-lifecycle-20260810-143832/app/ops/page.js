 "use client";

import { useEffect, useMemo, useState } from "react";
import { io } from "socket.io-client";

const statuses = ["new","accepted","shopping","ready","out_for_delivery","completed","cancelled"];

export default function Ops() {
  const [socket, setSocket] = useState(null);
  const [orders, setOrders] = useState([]);

  useEffect(() => {
    const s = io();
    setSocket(s);
    s.on("orders:snapshot", setOrders);
    s.on("order:created", o => setOrders(v => [o, ...v.filter(x => x.id !== o.id)]));
    s.on("order:updated", o => setOrders(v => v.map(x => x.id === o.id ? o : x)));
    s.on("order:location", ({ id, location }) => setOrders(v => v.map(x => x.id === id ? { ...x, runnerLocation: location } : x)));
    return () => s.disconnect();
  }, []);

  const active = useMemo(() => orders.filter(o => !["completed","cancelled"].includes(o.status)), [orders]);

  function update(o, status) {
    socket?.emit("order:update", { id: o.id, status });
  }

  return (
    <main className="shell">
      <div className="topbar"><div><span className="eyebrow">OPERATIONS</span><h1>Live Requests</h1></div><span className="live">● LIVE</span></div>
      <div className="stats"><div><b>{active.length}</b><span>Active</span></div><div><b>{orders.length}</b><span>Total</span></div></div>
      <div className="orderlist">
        {orders.length === 0 && <div className="panel"><h2>No requests yet</h2><p className="muted">Keep this screen open. New mobile requests appear here instantly.</p></div>}
        {orders.map(o => (
          <article className="order" key={o.id}>
            <div className="orderhead"><strong>#{o.id.slice(0,8)}</strong><span className={`status ${o.status}`}>{o.status.replaceAll("_"," ")}</span></div>
            <h2>{o.request}</h2>
            <div className="meta"><span>👤 {o.customer.name}</span><span>📞 {o.customer.phone}</span>{o.customer.email && <span>✉ {o.customer.email}</span>}</div>
            {o.notes && <p className="notes">{o.notes}</p>}
            {o.gps?.consented && <div className="location">📍 Customer GPS shared: {o.gps.lat.toFixed(5)}, {o.gps.lng.toFixed(5)} · ±{Math.round(o.gps.accuracy || 0)}m</div>}
            {o.runnerLocation && <div className="location">🏃 Runner: {o.runnerLocation.lat.toFixed(5)}, {o.runnerLocation.lng.toFixed(5)}</div>}
            <div className="controls">{statuses.map(s => <button key={s} className={s === o.status ? "selected" : ""} onClick={() => update(o,s)}>{s.replaceAll("_"," ")}</button>)}</div>
          </article>
        ))}
      </div>
    </main>
  );
}