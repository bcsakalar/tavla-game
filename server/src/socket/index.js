/**
 * Socket.IO initialization module.
 * Registers middleware and event handlers.
 */

const { socketAuth } = require('./middleware/auth');
const { socketRateLimitMiddleware } = require('./middleware/rateLimiter');
const { lobbyHandler } = require('./handlers/lobby');
const { gameHandler } = require('./handlers/game');
const { botHandler } = require('./handlers/bot');
const logger = require('../utils/logger');

function initSocket(io) {
  // Authentication middleware
  io.use(socketAuth);
  // Rate limiting middleware
  io.use(socketRateLimitMiddleware);

  io.on('connection', (socket) => {
    logger.info('Socket', `Bağlandı: ${socket.user.username} (${socket.id})`);

    // Register handlers
    lobbyHandler(io, socket);
    gameHandler(io, socket);
    botHandler(io, socket);

    socket.on('disconnect', (reason) => {
      logger.info('Socket', `Ayrıldı: ${socket.user.username} - ${reason}`);
    });
  });
}

module.exports = initSocket;
