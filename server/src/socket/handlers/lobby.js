/**
 * Lobby & Matchmaking handler.
 *
 * Events:
 *   lobby:queue      → join matchmaking queue
 *   lobby:cancel     → leave matchmaking queue
 *   lobby:online     → get online players count
 */

const { createGame, startGame, getGameSnapshot } = require('../../game/engine');
const gameService = require('../../services/gameService');
const stateStore = require('../../game/stateStore');
const config = require('../../config');
const logger = require('../../utils/logger');

// Matchmaking queue: Map<socketId, { userId, username, elo, joinedAt, socket }>
const queue = new Map();

// Active games: Map<gameId, gameInstance>
const activeGames = new Map();

// Player to game mapping: Map<userId, gameId>
const playerGames = new Map();

// Socket to user mapping
const socketUsers = new Map();

// Store io reference for periodic matchmaking
let _io = null;

function lobbyHandler(io, socket) {
  _io = io;
  const userId = socket.user.id;
  const username = socket.user.username;

  // Track connected user
  socketUsers.set(socket.id, userId);
  socket.join(`user:${userId}`);

  // Broadcast online count
  io.emit('lobby:onlineCount', socketUsers.size);

  // Join matchmaking queue
  socket.on('lobby:queue', () => {
    // Already in game?
    if (playerGames.has(userId)) {
      socket.emit('lobby:error', { message: 'Zaten bir oyundayız' });
      return;
    }

    // Already in queue?
    if (queue.has(socket.id)) {
      return;
    }

    const elo = socket.user.elo || 1200;
    queue.set(socket.id, {
      userId,
      username,
      elo,
      joinedAt: Date.now(),
      socket,
    });

    socket.emit('lobby:queued');
    tryMatchmaking(io);
  });

  // Cancel queue
  socket.on('lobby:cancel', () => {
    queue.delete(socket.id);
    socket.emit('lobby:cancelledQueue');
  });

  // Get online count
  socket.on('lobby:online', () => {
    socket.emit('lobby:onlineCount', socketUsers.size);
  });

  // Handle disconnect
  socket.on('disconnect', () => {
    queue.delete(socket.id);
    socketUsers.delete(socket.id);
    io.emit('lobby:onlineCount', socketUsers.size);
  });
}

/**
 * Try to match two players from the queue.
 */
function tryMatchmaking(io) {
  if (queue.size < 2) return;

  const entries = Array.from(queue.entries());

  for (let i = 0; i < entries.length; i++) {
    for (let j = i + 1; j < entries.length; j++) {
      const [socketIdA, playerA] = entries[i];
      const [socketIdB, playerB] = entries[j];

      // Same user check
      if (playerA.userId === playerB.userId) continue;

      const eloDiff = Math.abs(playerA.elo - playerB.elo);
      const waitTime = Math.max(
        Date.now() - playerA.joinedAt,
        Date.now() - playerB.joinedAt,
      );

      // Expand range over time
      const range = waitTime > config.game.matchmakingExpandAfterSeconds * 1000
        ? config.game.matchmakingRangeExpand
        : config.game.matchmakingRangeInitial;

      if (eloDiff <= range) {
        // Match found! Remove from queue
        queue.delete(socketIdA);
        queue.delete(socketIdB);

        createMatch(io, playerA, playerB);
        return;
      }
    }
  }
}

/**
 * Create a match between two players.
 */
async function createMatch(io, playerA, playerB) {
  // Randomly assign colors
  const isAWhite = Math.random() < 0.5;
  const whitePlayer = isAWhite ? playerA : playerB;
  const blackPlayer = isAWhite ? playerB : playerA;

  // Create game instance
  const game = createGame(whitePlayer.userId, blackPlayer.userId);
  const startResult = startGame(game);

  // Save to DB
  let dbGame;
  try {
    dbGame = await gameService.createGameRecord({
      whitePlayerId: whitePlayer.userId,
      blackPlayerId: blackPlayer.userId,
      board: game.board,
    });
    await gameService.updateDailyStats('total_games');
  } catch (err) {
    logger.error('Matchmaking', 'DB error', err);
    whitePlayer.socket.emit('lobby:error', { message: 'Oyun oluşturulamadı' });
    blackPlayer.socket.emit('lobby:error', { message: 'Oyun oluşturulamadı' });
    return;
  }

  const gameId = dbGame.id;

  // Store active game
  game.dbId = gameId;
  activeGames.set(gameId, game);
  playerGames.set(whitePlayer.userId, gameId);
  playerGames.set(blackPlayer.userId, gameId);

  // Persist to Redis
  stateStore.saveGame(gameId, game);
  stateStore.setPlayerGame(whitePlayer.userId, gameId);
  stateStore.setPlayerGame(blackPlayer.userId, gameId);

  // Join game room
  const roomName = `game:${gameId}`;
  whitePlayer.socket.join(roomName);
  blackPlayer.socket.join(roomName);

  // Send match found
  const matchData = {
    gameId,
    white: { userId: whitePlayer.userId, username: whitePlayer.username, elo: whitePlayer.elo },
    black: { userId: blackPlayer.userId, username: blackPlayer.username, elo: blackPlayer.elo },
    ...startResult,
    snapshot: getGameSnapshot(game),
  };

  io.to(roomName).emit('game:start', matchData);
}

// Run matchmaking periodically
setInterval(() => {
  // Retry for waiting players
  if (queue.size >= 2 && _io) {
    tryMatchmaking(_io);
  }
}, 5000);

module.exports = { lobbyHandler, activeGames, playerGames, queue, socketUsers };
