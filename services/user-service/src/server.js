const express = require('express');
const cors = require('cors');
const { connectDB } = require('./utils/database');
const { logger } = require('./utils/logger');
const userRoutes = require('./routes/users');

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(cors({
  origin: true, // Allow all origins in production - configure properly for production
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));

// Routes
app.use('/api/users', userRoutes);

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', service: 'user-service' });
});

// Error handling
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
const startServer = async () => {
  try {
    await connectDB();
    app.listen(PORT, () => {
      logger.info(`User service running on port ${PORT}`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();