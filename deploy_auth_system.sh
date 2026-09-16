#!/usr/bin/env bash
set -euo pipefail

# Define core directory structure
APP_DIR="auth_system"
mkdir -p "$APP_DIR/assets/css"
mkdir -p "$APP_DIR/assets/js"
mkdir -p "$APP_DIR/lib"
mkdir -p "$APP_DIR/routes"

# 1. Stylesheet (Executive Spectrum Palette: Obsidian, Gold, Teal)
cat <<'CSSEOF' > "$APP_DIR/assets/css/style.css"
:root {
  --bg-obsidian: #0b0e14;
  --panel-bg: #141821;
  --gold-primary: #d4af37;
  --gold-hover: #f1c40f;
  --teal-accent: #008080;
  --teal-bright: #20b2aa;
  --text-main: #e2e8f0;
  --text-muted: #94a3b8;
  --border-color: #2a3241;
  --error-color: #ef4444;
  --success-color: #10b981;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, sans-serif;
}

body {
  background-color: var(--bg-obsidian);
  color: var(--text-main);
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
}

header {
  width: 100%;
  max-width: 1200px;
  padding: 1.5rem 1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--border-color);
}

.brand {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--gold-primary);
  letter-spacing: 1px;
  text-decoration: none;
}

nav a {
  color: var(--text-muted);
  text-decoration: none;
  margin-left: 1.5rem;
  transition: color 0.2s ease;
}

nav a:hover, nav a.active {
  color: var(--teal-bright);
}

main.container {
  width: 100%;
  max-width: 480px;
  margin: auto;
  padding: 2rem 1rem;
}

.auth-card {
  background-color: var(--panel-bg);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 2.5rem 2rem;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
}

.auth-card h1 {
  font-size: 1.75rem;
  color: var(--gold-primary);
  margin-bottom: 0.5rem;
  text-align: center;
}

.auth-card p.subtitle {
  color: var(--text-muted);
  font-size: 0.9rem;
  margin-bottom: 1.5rem;
  text-align: center;
}

.tab-group {
  display: flex;
  margin-bottom: 1.5rem;
  border-bottom: 2px solid var(--border-color);
}

.tab-btn {
  flex: 1;
  padding: 0.75rem;
  background: none;
  border: none;
  color: var(--text-muted);
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.tab-btn.active {
  color: var(--teal-bright);
  border-bottom: 2px solid var(--teal-bright);
  margin-bottom: -2px;
}

.form-group {
  margin-bottom: 1.25rem;
}

.form-group label {
  display: block;
  font-size: 0.85rem;
  color: var(--text-main);
  margin-bottom: 0.5rem;
}

.form-group input {
  width: 100%;
  padding: 0.85rem 1rem;
  background-color: var(--bg-obsidian);
  border: 1px solid var(--border-color);
  border-radius: 4px;
  color: var(--text-main);
  font-size: 1rem;
  outline: none;
  transition: border-color 0.2s ease;
}

.form-group input:focus {
  border-color: var(--teal-bright);
}

.btn-primary {
  width: 100%;
  padding: 0.85rem;
  background-color: var(--gold-primary);
  color: var(--bg-obsidian);
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 0.2s ease;
  margin-top: 0.5rem;
}

.btn-primary:hover {
  background-color: var(--gold-hover);
}

.alert {
  padding: 0.75rem 1rem;
  border-radius: 4px;
  font-size: 0.85rem;
  margin-bottom: 1rem;
  display: none;
}

.alert-error {
  background-color: rgba(239, 68, 68, 0.15);
  border: 1px solid var(--error-color);
  color: var(--error-color);
}

.alert-success {
  background-color: rgba(16, 185, 129, 0.15);
  border: 1px solid var(--success-color);
  color: var(--success-color);
}

.auth-footer-links {
  margin-top: 1.5rem;
  text-align: center;
  font-size: 0.85rem;
}

.auth-footer-links a {
  color: var(--teal-bright);
  text-decoration: none;
}

.auth-footer-links a:hover {
  text-decoration: underline;
}

footer {
  width: 100%;
  max-width: 1200px;
  padding: 1.5rem 1rem;
  text-align: center;
  color: var(--text-muted);
  font-size: 0.8rem;
  border-top: 1px solid var(--border-color);
}

@media (max-width: 600px) {
  header {
    flex-direction: column;
    gap: 1rem;
  }
  nav a {
    margin: 0 0.75rem;
  }
  .auth-card {
    padding: 1.5rem 1rem;
  }
}
CSSEOF

# 2. Database & State Simulation Layer (Pure JS LocalStorage Store)
cat <<'JSEOF' > "$APP_DIR/assets/js/store.js"
const AuthStore = {
  getUsers: () => JSON.parse(localStorage.getItem('sys_users') || '[]'),
  saveUsers: (users) => localStorage.setItem('sys_users', JSON.stringify(users)),
  getOTPs: () => JSON.parse(localStorage.getItem('sys_otps') || '{}'),
  saveOTPs: (otps) => localStorage.setItem('sys_otps', JSON.stringify(otps)),
  getSession: () => JSON.parse(localStorage.getItem('sys_session') || 'null'),
  setSession: (user) => localStorage.setItem('sys_session', JSON.stringify(user)),
  clearSession: () => localStorage.removeItem('sys_session'),

  // Notification simulation replacing autofill in input fields
  sendDispatch: (target, code, channel) => {
    const otps = AuthStore.getOTPs();
    otps[target] = { code: String(code), expires: Date.now() + 300000 };
    AuthStore.saveOTPs(otps);

    // Simulated SMS/Email Gateway Terminal Log
    console.log(`[DISPATCH SYSTEM] Channel: ${channel.toUpperCase()} | Destination: ${target} | Code: ${code}`);
    alert(`[SIMULATED ${channel.toUpperCase()} DISPATCH]\n\nA verification code has been dispatched to ${target}.\n\n(Simulated OTP Code: ${code})`);
  },

  verifyOTP: (target, code) => {
    const otps = AuthStore.getOTPs();
    const record = otps[target];
    if (!record) return false;
    if (Date.now() > record.expires) return false;
    if (record.code === String(code).trim()) {
      delete otps[target];
      AuthStore.saveOTPs(otps);
      return true;
    }
    return false;
  }
};
JSEOF

# 3. Main Routing & Flow Logic
cat <<'JSEOF' > "$APP_DIR/assets/js/app.js"
document.addEventListener('DOMContentLoaded', () => {
  AuthApp.init();
});

const AuthApp = {
  init: () => {
    AuthApp.updateNav();
  },

  updateNav: () => {
    const session = AuthStore.getSession();
    const nav = document.getElementById('main-nav');
    if (!nav) return;

    if (session) {
      nav.innerHTML = `
        <a href="dashboard.html">Dashboard</a>
        <a href="profile.html">Profile</a>
        <a href="settings.html">Settings</a>
        <a href="#" id="logout-link">Logout (${session.identity})</a>
      `;
      document.getElementById('logout-link')?.addEventListener('click', (e) => {
        e.preventDefault();
        AuthStore.clearSession();
        window.location.href = 'index.html';
      });
    } else {
      nav.innerHTML = `
        <a href="index.html">Home</a>
        <a href="login.html">Login</a>
        <a href="register-email.html">Email Sign Up</a>
        <a href="register-phone.html">Phone Sign Up</a>
      `;
    }
  },

  showAlert: (msg, type = 'error') => {
    const box = document.getElementById('alert-box');
    if (!box) return;
    box.className = `alert alert-${type}`;
    box.textContent = msg;
    box.style.display = 'block';
  }
};
JSEOF

# 4. Global Structural Component (Header & Footer) Injector Script
cat <<'JSEOF' > "$APP_DIR/assets/js/layout.js"
function renderLayout(titleText) {
  document.getElementById('site-header').innerHTML = `
    <a href="index.html" class="brand">EXECUTIVE AUTH</a>
    <nav id="main-nav"></nav>
  `;
  document.getElementById('site-footer').innerHTML = `
    &copy; ${new Date().getFullYear()} Executive Auth Architecture. Standalone Zero-Dependency System.
  `;
  if (titleText) {
    document.title = `${titleText} | Executive Auth Architecture`;
  }
}
JSEOF

# 5. Index Page
cat <<'HTMLEOF' > "$APP_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Home | Executive Auth Architecture</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="container">
    <div class="auth-card" style="text-align: center;">
      <h1>Authentication Portal</h1>
      <p class="subtitle">Secure, isolated email and phone verification flows.</p>
      <div style="display: flex; flex-direction: column; gap: 1rem; margin-top: 2rem;">
        <a href="register-email.html" class="btn-primary" style="text-decoration:none;">Register via Email</a>
        <a href="register-phone.html" class="btn-primary" style="text-decoration:none; background-color: var(--teal-accent); color: #fff;">Register via Mobile SMS</a>
        <a href="login.html" style="color: var(--teal-bright); text-decoration: none; margin-top: 1rem;">Already have an account? Sign In</a>
      </div>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Home");
  </script>
</body>
</html>
HTMLEOF

# 6. Email Registration Form
cat <<'HTMLEOF' > "$APP_DIR/register-email.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Email Registration</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="container">
    <div class="auth-card">
      <h1>Create Account</h1>
      <p class="subtitle">Email Authentication Channel</p>

      <div class="tab-group">
        <button class="tab-btn active" onclick="location.href='register-email.html'">Email Sign Up</button>
        <button class="tab-btn" onclick="location.href='register-phone.html'">Phone Sign Up</button>
      </div>

      <div id="alert-box" class="alert"></div>

      <form id="email-form">
        <div class="form-group">
          <label for="email">Email Address</label>
          <input type="email" id="email" placeholder="name@company.com" required>
        </div>
        <div class="form-group">
          <label for="password">Password</label>
          <input type="password" id="password" required>
        </div>
        <button type="submit" class="btn-primary">Send Email Verification Code</button>
      </form>

      <div class="auth-footer-links">
        <a href="login.html">Already registered? Log In</a>
      </div>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Email Registration");
    
    document.getElementById('email-form').addEventListener('submit', (e) => {
      e.preventDefault();
      const email = document.getElementById('email').value.trim();
      const password = document.getElementById('password').value;

      const users = AuthStore.getUsers();
      if (users.find(u => u.identity === email)) {
        AuthApp.showAlert("An account with this email already exists.");
        return;
      }

      const code = Math.floor(100000 + Math.random() * 900000);
      sessionStorage.setItem('pending_user', JSON.stringify({ identity: email, type: 'email', password }));
      AuthStore.sendDispatch(email, code, 'email');
      
      window.location.href = 'verify.html';
    });
  </script>
</body>
</html>
HTMLEOF

# 7. SMS/Phone Registration Form
cat <<'HTMLEOF' > "$APP_DIR/register-phone.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Phone Registration</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="container">
    <div class="auth-card">
      <h1>Create Account</h1>
      <p class="subtitle">Mobile SMS Channel</p>

      <div class="tab-group">
        <button class="tab-btn" onclick="location.href='register-email.html'">Email Sign Up</button>
        <button class="tab-btn active" onclick="location.href='register-phone.html'">Phone Sign Up</button>
      </div>

      <div id="alert-box" class="alert"></div>

      <form id="phone-form">
        <div class="form-group">
          <label for="phone">Mobile Phone Number</label>
          <input type="tel" id="phone" placeholder="+1 (555) 000-0000" required>
        </div>
        <div class="form-group">
          <label for="password">Password</label>
          <input type="password" id="password" required>
        </div>
        <button type="submit" class="btn-primary" style="background-color: var(--teal-accent); color:#fff;">Send SMS Verification Code</button>
      </form>

      <div class="auth-footer-links">
        <a href="login.html">Already registered? Log In</a>
      </div>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Phone Registration");

    document.getElementById('phone-form').addEventListener('submit', (e) => {
      e.preventDefault();
      const phone = document.getElementById('phone').value.trim();
      const password = document.getElementById('password').value;

      const users = AuthStore.getUsers();
      if (users.find(u => u.identity === phone)) {
        AuthApp.showAlert("An account with this phone number already exists.");
        return;
      }

      const code = Math.floor(100000 + Math.random() * 900000);
      sessionStorage.setItem('pending_user', JSON.stringify({ identity: phone, type: 'phone', password }));
      AuthStore.sendDispatch(phone, code, 'sms');

      window.location.href = 'verify.html';
    });
  </script>
</body>
</html>
HTMLEOF

# 8. Verification Page (Clean input field - OTP delivered via dispatch alert/console)
cat <<'HTMLEOF' > "$APP_DIR/verify.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Security Verification</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="container">
    <div class="auth-card">
      <h1>Verify Account</h1>
      <p class="subtitle" id="verify-target-desc">Enter the verification code sent to your device.</p>

      <div id="alert-box" class="alert"></div>

      <form id="verify-form">
        <div class="form-group">
          <label for="auth-code">Authorization Code</label>
          <input type="text" id="auth-code" placeholder="Enter 6-digit code" autocomplete="off" required>
        </div>
        <button type="submit" class="btn-primary">Verify & Create Account</button>
      </form>

      <div class="auth-footer-links">
        <a href="#" id="resend-link">Resend Code</a>
      </div>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Security Verification");

    const pending = JSON.parse(sessionStorage.getItem('pending_user') || 'null');
    if (!pending) {
      window.location.href = 'index.html';
    } else {
      document.getElementById('verify-target-desc').textContent = 
        `Enter the code dispatched to your ${pending.type === 'email' ? 'email address' : 'phone number'}: ${pending.identity}`;
    }

    document.getElementById('verify-form').addEventListener('submit', (e) => {
      e.preventDefault();
      const code = document.getElementById('auth-code').value;

      if (AuthStore.verifyOTP(pending.identity, code)) {
        const users = AuthStore.getUsers();
        users.push({ identity: pending.identity, type: pending.type, password: pending.password });
        AuthStore.saveUsers(users);

        AuthStore.setSession({ identity: pending.identity, type: pending.type });
        sessionStorage.removeItem('pending_user');
        window.location.href = 'dashboard.html';
      } else {
        AuthApp.showAlert("Invalid or expired verification code. Please try again.");
      }
    });

    document.getElementById('resend-link').addEventListener('click', (e) => {
      e.preventDefault();
      const code = Math.floor(100000 + Math.random() * 900000);
      AuthStore.sendDispatch(pending.identity, code, pending.type === 'email' ? 'email' : 'sms');
      AuthApp.showAlert("A new code has been dispatched.", "success");
    });
  </script>
</body>
</html>
HTMLEOF

# 9. Login Page
cat <<'HTMLEOF' > "$APP_DIR/login.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Login</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="container">
    <div class="auth-card">
      <h1>Account Login</h1>
      <p class="subtitle">Access your account dashboard</p>

      <div id="alert-box" class="alert"></div>

      <form id="login-form">
        <div class="form-group">
          <label for="identity">Email or Phone Number</label>
          <input type="text" id="identity" placeholder="Email address or phone number" required>
        </div>
        <div class="form-group">
          <label for="password">Password</label>
          <input type="password" id="password" required>
        </div>
        <button type="submit" class="btn-primary">Sign In</button>
      </form>

      <div class="auth-footer-links">
        <a href="forgot-password.html">Forgot Password?</a><br><br>
        <a href="register-email.html">Need an account? Register here</a>
      </div>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Login");

    document.getElementById('login-form').addEventListener('submit', (e) => {
      e.preventDefault();
      const identity = document.getElementById('identity').value.trim();
      const password = document.getElementById('password').value;

      const users = AuthStore.getUsers();
      const user = users.find(u => u.identity === identity && u.password === password);

      if (user) {
        AuthStore.setSession({ identity: user.identity, type: user.type });
        window.location.href = 'dashboard.html';
      } else {
        AuthApp.showAlert("Invalid credentials provided. Please try again.");
      }
    });
  </script>
</body>
</html>
HTMLEOF

# 10. Password Reset Flow
cat <<'HTMLEOF' > "$APP_DIR/forgot-password.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Reset Password</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="container">
    <div class="auth-card">
      <h1>Password Recovery</h1>
      <p class="subtitle">Dispatch recovery key via Email or SMS</p>

      <div id="alert-box" class="alert"></div>

      <form id="forgot-form">
        <div class="form-group">
          <label for="identity">Registered Email or Phone</label>
          <input type="text" id="identity" placeholder="Enter email or phone" required>
        </div>
        <button type="submit" class="btn-primary">Send Reset Instructions</button>
      </form>

      <div class="auth-footer-links">
        <a href="login.html">Back to Login</a>
      </div>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Reset Password");

    document.getElementById('forgot-form').addEventListener('submit', (e) => {
      e.preventDefault();
      const identity = document.getElementById('identity').value.trim();
      const users = AuthStore.getUsers();
      const user = users.find(u => u.identity === identity);

      if (!user) {
        AuthApp.showAlert("Target identity not found in record.");
        return;
      }

      const code = Math.floor(100000 + Math.random() * 900000);
      AuthStore.sendDispatch(identity, code, user.type === 'email' ? 'email' : 'sms');
      AuthApp.showAlert("Reset code sent! Check your notification dispatch.", "success");
    });
  </script>
</body>
</html>
HTMLEOF

# 11. Complete Page Ecosystem: Dashboard Page
cat <<'HTMLEOF' > "$APP_DIR/dashboard.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Dashboard</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="container" style="max-width: 800px;">
    <div class="auth-card">
      <h1>Dashboard Overview</h1>
      <p class="subtitle">System Status and User Metadata</p>
      
      <div id="dashboard-content" style="margin-top: 1.5rem; text-align: left;">
        <!-- Hydrated dynamically -->
      </div>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Dashboard");

    const session = AuthStore.getSession();
    if (!session) {
      window.location.href = 'login.html';
    } else {
      document.getElementById('dashboard-content').innerHTML = `
        <div style="background: var(--bg-obsidian); padding: 1.5rem; border-radius: 4px; border: 1px solid var(--border-color);">
          <p><strong>Authenticated Identifier:</strong> ${session.identity}</p>
          <p style="margin-top:0.5rem;"><strong>Registration Channel:</strong> ${session.type.toUpperCase()}</p>
          <p style="margin-top:0.5rem;"><strong>System Status:</strong> <span style="color:var(--success-color);">Active / Verified</span></p>
        </div>
      `;
    }
  </script>
</body>
</html>
HTMLEOF

# 12. Complete Page Ecosystem: Profile Page
cat <<'HTMLEOF' > "$APP_DIR/profile.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>User Profile</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="container" style="max-width: 600px;">
    <div class="auth-card">
      <h1>Account Profile</h1>
      <p class="subtitle">Manage user details</p>

      <form id="profile-form">
        <div class="form-group">
          <label>Identifier</label>
          <input type="text" id="prof-id" disabled style="opacity: 0.6;">
        </div>
        <div class="form-group">
          <label for="display-name">Display Name</label>
          <input type="text" id="display-name" placeholder="Executive User">
        </div>
        <button type="submit" class="btn-primary">Update Details</button>
      </form>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("User Profile");

    const session = AuthStore.getSession();
    if (!session) {
      window.location.href = 'login.html';
    } else {
      document.getElementById('prof-id').value = session.identity;
      document.getElementById('profile-form').addEventListener('submit', (e) => {
        e.preventDefault();
        alert('Profile updated successfully.');
      });
    }
  </script>
</body>
</html>
HTMLEOF

# 13. Complete Page Ecosystem: Settings Page
cat <<'HTMLEOF' > "$APP_DIR/settings.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Settings</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="container" style="max-width: 600px;">
    <div class="auth-card">
      <h1>System Settings</h1>
      <p class="subtitle">Security & Dispatch Configuration</p>

      <div style="text-align: left; display: flex; flex-direction: column; gap: 1rem;">
        <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer;">
          <input type="checkbox" checked disabled> Enable SMS / Email Gateway Simulations
        </label>
        <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer;">
          <input type="checkbox" checked disabled> High-contrast Obsidian & Gold Theme
        </label>
      </div>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Settings");

    if (!AuthStore.getSession()) {
      window.location.href = 'login.html';
    }
  </script>
</body>
</html>
HTMLEOF

# 14. Server Execution Helper Engine
cat <<'PYEOF' > "$APP_DIR/server.py"
import http.server
import socketserver
import os

PORT = 8080
Handler = http.server.SimpleHTTPRequestHandler

os.chdir(os.path.dirname(os.path.abspath(__file__)))

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Executive Auth Architecture running live at: http://localhost:{PORT}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server.")
PYEOF

chmod +x "$APP_DIR/server.py"
echo "Deployment Script Created. Executing server initialization..."
python3 "$APP_DIR/server.py"
