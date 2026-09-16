import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';

export default function Dashboard() {
  const [user, setUser] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchUser = async () => {
      try {
        const token = localStorage.getItem('token');
        const res = await fetch('/api/auth/me', {
          headers: { Authorization: `Bearer ${token}` }
        });
        if (!res.ok) throw new Error('Unauthorized');
        const data = await res.json();
        setUser(data);
      } catch (err) {
        localStorage.removeItem('token');
        navigate('/login');
      }
    };
    fetchUser();
  }, [navigate]);

  const handleLogout = () => {
    localStorage.removeItem('token');
    navigate('/login');
  };

  return (
    <div className="auth-container" style={{ maxWidth: '600px' }}>
      <h2>Dashboard</h2>
      {user ? (
        <div>
          <p>Welcome back! You are logged in as:</p>
          <p><strong>{user.email}</strong></p>
          <button onClick={handleLogout} style={{ marginTop: '1rem', backgroundColor: '#dc2626' }}>Sign Out</button>
        </div>
      ) : (
        <p>Loading session...</p>
      )}
    </div>
  );
}
