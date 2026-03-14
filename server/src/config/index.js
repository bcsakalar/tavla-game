require('dotenv').config();

const config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT, 10) || 3000,

  db: {
    connectionString: process.env.DATABASE_URL,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  },

  jwt: {
    secret: process.env.JWT_SECRET,
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  },

  session: {
    secret: process.env.SESSION_SECRET,
  },

  game: {
    moveTimerSeconds: parseInt(process.env.MOVE_TIMER_SECONDS, 10) || 60,
    reconnectWindowSeconds: parseInt(process.env.RECONNECT_WINDOW_SECONDS, 10) || 60,
    eloKFactor: parseInt(process.env.ELO_K_FACTOR, 10) || 32,
    matchmakingRangeInitial: parseInt(process.env.MATCHMAKING_RANGE_INITIAL, 10) || 200,
    matchmakingRangeExpand: parseInt(process.env.MATCHMAKING_RANGE_EXPAND, 10) || 400,
    matchmakingExpandAfterSeconds: parseInt(process.env.MATCHMAKING_EXPAND_AFTER_SECONDS, 10) || 30,
  },

  cors: {
    origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  },
};

module.exports = config;
