/**
 * Socket.IO initialization module.
 * Registers middleware and event handlers.
 */

const { socketAuth } = require('./middleware/auth');
const { lobbyHandler } = require('./handlers/lobby');
const { gameHandler } = require('./handlers/game');
const { botHandler } = require('./handlers/bot');

function initSocket(io) {
  // Authentication middleware
  io.use(socketAuth);

  io.on('connection', (socket) => {
    console.warn(`[Socket] Bağlandı: ${socket.user.username} (${socket.id})`);

    // Register handlers
    lobbyHandler(io, socket);
    gameHandler(io, socket);
    botHandler(io, socket);

    socket.on('disconnect', (reason) => {
      console.warn(`[Socket] Ayrıldı: ${socket.user.username} - ${reason}`);
    });
  });
}

module.exports = initSocket;
