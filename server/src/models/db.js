const { Pool } = require('pg');
const config = require('../config');
const logger = require('../utils/logger');

const pool = new Pool(config.db);

pool.on('error', (err) => {
  logger.error('DB', 'Unexpected database pool error', err);
  // Do NOT process.exit — pool will recover automatically
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  getClient: () => pool.connect(),
  pool,
};
