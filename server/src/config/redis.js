/**
 * Redis client (ioredis).
 * Falls back gracefully if Redis is unavailable — game state stays in-memory only.
 */

const config = require('./index');
const logger = require('../utils/logger');

let redis = null;

try {
  const Redis = require('ioredis');
  redis = new Redis(config.redis.url, {
    keyPrefix: config.redis.keyPrefix,
    maxRetriesPerRequest: 3,
    retryStrategy(times) {
      if (times > 5) return null; // Stop retrying
      return Math.min(times * 200, 2000);
    },
  });

  redis.on('error', (err) => {
    logger.warn('Redis', `Connection error: ${err.message}`);
  });

  redis.on('connect', () => {
    logger.info('Redis', 'Connected');
  });
} catch {
  logger.warn('Redis', 'ioredis not installed — running without Redis persistence');
}

module.exports = redis;
