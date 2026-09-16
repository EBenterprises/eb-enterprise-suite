export default function Navigation() {
  return (
    <nav className="nav" aria-label="Primary navigation">
      <a href="/dashboard">Dashboard</a>
      <a href="/errands/new">New Errand</a>
      <a href="/requests">Requests</a>
      <a href="/deliveries">Deliveries</a>
      <a href="/messages">Messages</a>
      <a href="/profile">Profile</a>
    </nav>
  );
}
