const { server, io } = require('./app');
const config = require('./config');
const db = require('./models/db');
const logger = require('./utils/logger');
const stateStore = require('./game/stateStore');

let isShuttingDown = false;

async function shutdown(signal) {
  if (isShuttingDown) return;
  isShuttingDown = true;
  logger.info('Server', `${signal} received — shutting down gracefully`);

  // Save active game states to Redis before shutting down
  try {
    const { activeGames } = require('./socket/handlers/lobby');
    await stateStore.saveAllGames(activeGames);
  } catch (err) {
    logger.error('StateStore', 'Error saving games on shutdown', err);
  }

  // Stop accepting new connections
  server.close(() => {
    logger.info('Server', 'HTTP server closed');
  });

  // Close all Socket.IO connections
  try {
    io.disconnectSockets(true);
    logger.info('Socket', 'All sockets disconnected');
  } catch (err) {
    logger.error('Socket', 'Error disconnecting sockets', err);
  }

  // Close DB pool
  try {
    await db.pool.end();
    logger.info('DB', 'Connection pool closed');
  } catch (err) {
    logger.error('DB', 'Error closing pool', err);
  }

  process.exit(0);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

async function start(retries = 5) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      // Test database connection
      await db.query('SELECT NOW()');
      logger.info('DB', 'PostgreSQL bağlantısı başarılı');

      server.listen(config.port, () => {
        logger.info('Server', `Tavla Online - Port ${config.port} - ${config.env}`);
      });
      return; // Success — exit loop
    } catch (err) {
      logger.error('Server', `Başlatma hatası (deneme ${attempt}/${retries})`, err);
      if (attempt < retries) {
        const delay = attempt * 2000; // 2s, 4s, 6s, 8s, 10s
        logger.info('Server', `${delay / 1000}s sonra tekrar denenecek...`);
        await new Promise(r => setTimeout(r, delay));
      } else {
        logger.error('Server', 'Tüm denemeler başarısız — çıkılıyor');
        process.exit(1);
      }
    }
  }
}

start();
