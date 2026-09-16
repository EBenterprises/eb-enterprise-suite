 "use client";

import { useEffect, useState } from "react";
import { io } from "socket.io-client";

export default function RequestPage() {
  const [socket, setSocket] = useState(null);
  const [form, setForm] = useState({ name: "", phone: "", email: "", request: "", notes: "" });
  const [gps, setGps] = useState({ consented: false });
  const [message, setMessage] = useState("");

  useEffect(() => {
    const s = io();
    setSocket(s);
    return () => s.disconnect();
  }, []);

  function field(key) {
    return e => setForm(v => ({ ...v, [key]: e.target.value }));
  }

  function shareLocation() {
    if (!navigator.geolocation) return setMessage("This device does not provide GPS.");
    navigator.geolocation.getCurrentPosition(
      p => {
        setGps({ consented: true, lat: p.coords.latitude, lng: p.coords.longitude, accuracy: p.coords.accuracy });
        setMessage("Location permission granted for this request.");
      },
      () => setMessage("Location was not shared. You can still submit the request.")
    );
  }

  function submit(e) {
    e.preventDefault();
    if (!socket) return setMessage("Connecting to server…");
    setMessage("Sending…");
    socket.emit("order:create", { customer: { name: form.name, phone: form.phone, email: form.email }, request: form.request, notes: form.notes, gps }, r => {
      if (r?.ok) {
        setMessage(`Request ${r.order.id.slice(0, 8)} received.`);
        setForm({ name: "", phone: "", email: "", request: "", notes: "" });
      } else setMessage(r?.error || "Could not submit.");
    });
  }

  return (
    <main className="shell narrow">
      <a className="back" href="/">← Home</a>
      <div className="panel">
        <span className="eyebrow">MEMBER INTAKE</span>
        <h1>What are you looking for?</h1>
        <p className="muted">Write the request naturally. Example: “I’m looking for 10 grilled cheeses and 2 Big Macs.”</p>
        <form onSubmit={submit}>
          <label>Name<input required value={form.name} onChange={field("name")} /></label>
          <label>Phone<input required type="tel" value={form.phone} onChange={field("phone")} /></label>
          <label>Email <small>optional</small><input type="email" value={form.email} onChange={field("email")} /></label>
          <label>Your request<textarea required rows="5" placeholder="Tell us what you are looking for…" value={form.request} onChange={field("request")} /></label>
          <label>Notes <small>optional</small><textarea rows="3" value={form.notes} onChange={field("notes")} /></label>
          <div className="gpsbox">
            <div><b>Share GPS location with runners</b><span>{gps.consented ? "Location shared for this request." : "Only share when you explicitly allow it."}</span></div>
            <button type="button" className="button" onClick={shareLocation}>{gps.consented ? "Location Shared" : "Share Location"}</button>
          </div>
          <button className="button primary full" type="submit">Submit Request</button>
          {message && <div className="notice">{message}</div>}
        </form>
      </div>
    </main>
  );
}