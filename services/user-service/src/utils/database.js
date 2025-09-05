const { Pool } = require('pg');
const { logger } = require('./logger');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'user_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

const connectDB = async () => {
  try {
    await pool.connect();
    logger.info('Connected to PostgreSQL database');
  } catch (error) {
    logger.error('Database connection failed:', error);
    throw error;
  }
};

const query = (text, params) => pool.query(text, params);

module.exports = { connectDB, query };