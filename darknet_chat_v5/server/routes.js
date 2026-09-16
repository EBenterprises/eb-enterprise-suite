
// Register Forgot Password Endpoints
const authController = require('./auth_controller');
app.post('/api/auth/forgot-password', authController.requestPasswordReset);
app.post('/api/auth/reset-password', authController.executePasswordReset);
