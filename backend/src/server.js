const express = require('express');
const app = express();
const PORT = 5000;

// Root route
app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Backend!',
    version: '1',
    environment: process.env.ENV || 'unknown',
    timestamp: new Date().toISOString()
  });
});

// Hello route (called by frontend)
app.get('/hello', (req, res) => {
  res.json({
    message: 'Hello from Backend API!',
    version: '1',
    environment: process.env.ENV || 'unknown',
    timestamp: new Date().toISOString()
  });
});

// Health check route (used by deployment scripts)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', version: '1' });
});

app.listen(PORT, () => {
  console.log(`Backend running on port ${PORT}`);
});
