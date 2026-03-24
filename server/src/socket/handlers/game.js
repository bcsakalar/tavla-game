/**
 * Game event handler.
 *
 * Events:
 *   game:rollDice      → roll dice for current turn
 *   game:move          → make a move { from, to, dieValue }
 *   game:undoMove      → undo last move in current turn
 *   game:endTurn       → explicitly end turn (when no more moves)
 *   game:resign        → resign from game
 *   game:chat          → send chat message
 *   game:emoji         → send quick emoji reaction
 *   game:reconnect     → reconnect to an active game
 */

const {
  rollTurnDice, makeMove, resignGame, getGameSnapshot,
  getPlayerColor, GameState, isTurnComplete, undoLastMove,
} = require('../../game/engine');
const { serializeBoard } = require('../../game/board');
const { calculateEloChange } = require('../../game/scoring');
const gameService = require('../../services/gameService');
const userService = require('../../services/userService');
const {  activeGames, playerGames } = require('./lobby');
const config = require('../../config');
const logger = require('../../utils/logger');
const { ALLOWED_EMOJIS, CHAT_MESSAGE_MAX_LENGTH } = require('../../config/constants');
const stateStore = require('../../game/stateStore');

// Turn timers: Map<gameId, timeoutId>
const turnTimers = new Map();

// Disconnect timers: Map<`${gameId}:${userId}`, timeoutId>
const disconnectTimers = new Map();

/**
 * Validate incoming move data from client.
 * Returns sanitised { from, to, dieValue } or null if invalid.
 */
function validateMoveData(data) {
  if (!data || typeof data !== 'object') return null;

  const from = data.from;
  const to = data.to;

  // from: integer 0-23 or 'bar'
  const validFrom =
    from === 'bar' || (Number.isInteger(from) && from >= 0 && from <= 23);
  // to: integer 0-23 or 'off'
  const validTo =
    to === 'off' || (Number.isInteger(to) && to >= 0 && to <= 23);

  if (!validFrom || !validTo) return null;

  // dieValue is optional (can be calculated), but if present must be 1-6
  let dieValue = data.dieValue;
  if (dieValue !== undefined && dieValue !== null) {
    dieValue = Number(dieValue);
    if (!Number.isInteger(dieValue) || dieValue < 1 || dieValue > 6) return null;
  } else {
    dieValue = undefined;
  }

  return { from, to, dieValue };
}

function gameHandler(io, socket) {
  const userId = socket.user.id;

  // Roll dice
  socket.on('game:rollDice', () => {
    if (!socket.rateLimitCheck('game:rollDice')) return;

    const gameId = playerGames.get(userId);
    if (!gameId) return socket.emit('game:error', { message: 'Aktif oyun yok' });

    const game = activeGames.get(gameId);
    if (!game) return;

    const color = getPlayerColor(game, userId);
    if (!color || game.currentTurn !== color) {
      return socket.emit('game:error', { message: 'Sıra sizde değil' });
    }

    const result = rollTurnDice(game);
    if (!result.success) {
      return socket.emit('game:error', { message: result.error });
    }

    const roomName = `game:${gameId}`;

    if (result.autoSkip) {
      io.to(roomName).emit('game:diceRolled', {
        dice: result.dice,
        autoSkip: true,
        nextTurn: result.nextTurn,
        snapshot: getGameSnapshot(game),
      });
      startTurnTimer(io, gameId, game);
    } else {
      io.to(roomName).emit('game:diceRolled', {
        dice: result.dice,
        autoSkip: false,
        snapshot: getGameSnapshot(game),
      });
      startTurnTimer(io, gameId, game);
    }
  });

  // Make a move
  socket.on('game:move', (moveData) => {
    if (!socket.rateLimitCheck('game:move')) return;

    const validated = validateMoveData(moveData);
    if (!validated) return socket.emit('game:error', { message: 'Geçersiz hamle verisi' });

    const gameId = playerGames.get(userId);
    if (!gameId) return socket.emit('game:error', { message: 'Aktif oyun yok' });

    const game = activeGames.get(gameId);
    if (!game) return;

    const color = getPlayerColor(game, userId);
    if (!color) return;

    // Calculate dieValue from coordinates if not provided
    let dieValue = validated.dieValue;
    if (dieValue === undefined) {
      if (validated.from === 'bar') {
        dieValue = color === 'W' ? (24 - validated.to) : (validated.to + 1);
      } else if (validated.to === 'off') {
        dieValue = color === 'W' ? (validated.from + 1) : (24 - validated.from);
      } else {
        dieValue = color === 'W' ? (validated.from - validated.to) : (validated.to - validated.from);
      }
    }

    const move = {
      from: validated.from,
      to: validated.to,
      dieValue,
      isHit: false,
    };

    // Determine if it's a hit
    if (move.to !== 'off' && move.to >= 0 && move.to < 24) {
      const targetPoint = game.board.points[move.to];
      const { opponent } = require('../../game/board');
      move.isHit = targetPoint.length === 1 && targetPoint[0] === opponent(color);
    }

    const result = makeMove(game, color, move);
    if (!result.success) {
      return socket.emit('game:error', { message: result.error });
    }

    const roomName = `game:${gameId}`;

    if (result.gameOver) {
      clearTurnTimer(gameId);
      handleGameEnd(io, gameId, game, result);
    } else if (result.turnOver) {
      clearTurnTimer(gameId);
      io.to(roomName).emit('game:moved', {
        move: moveData,
        turnOver: true,
        nextTurn: result.nextTurn,
        snapshot: getGameSnapshot(game),
      });
      startTurnTimer(io, gameId, game);
    } else {
      io.to(roomName).emit('game:moved', {
        move: moveData,
        turnOver: false,
        remainingDice: result.remainingDice,
        snapshot: getGameSnapshot(game),
      });
    }
  });

  // End turn explicitly
  socket.on('game:endTurn', () => {
    const gameId = playerGames.get(userId);
    if (!gameId) return;

    const game = activeGames.get(gameId);
    if (!game) return;

    const color = getPlayerColor(game, userId);
    if (!color || game.currentTurn !== color) return;

    if (isTurnComplete(game)) {
      const { switchTurn, recordTurnMoves } = require('../../game/engine');
      // Record turn moves if any
      if (game.movesThisTurn.length > 0) {
        recordTurnMoves(game);
      }

      clearTurnTimer(gameId);
      const nextTurn = switchTurn(game);
      const roomName = `game:${gameId}`;

      io.to(roomName).emit('game:turnEnded', {
        nextTurn,
        snapshot: getGameSnapshot(game),
      });
      startTurnTimer(io, gameId, game);
    }
  });

  // Resign
  socket.on('game:resign', () => {
    const gameId = playerGames.get(userId);
    if (!gameId) return;

    const game = activeGames.get(gameId);
    if (!game) return;

    const color = getPlayerColor(game, userId);
    if (!color) return;

    const result = resignGame(game, color);
    if (result.success) {
      clearTurnTimer(gameId);
      handleGameEnd(io, gameId, game, result);
    }
  });

  // Chat
  socket.on('game:chat', async (data) => {
    if (!socket.rateLimitCheck('game:chat')) return;

    const gameId = playerGames.get(userId);
    if (!gameId) return;

    const message = typeof data.message === 'string' ? data.message.trim().slice(0, 500) : '';
    if (!message) return;

    try {
      await gameService.saveChatMessage(gameId, userId, message);
      const roomName = `game:${gameId}`;
      io.to(roomName).emit('game:chatMessage', {
        userId,
        username: socket.user.username,
        message,
        timestamp: new Date(),
      });
    } catch (err) {
      logger.error('Chat', 'Message save failed', err);
    }
  });

  // Reconnect to active game
  socket.on('game:reconnect', () => {
    const gameId = playerGames.get(userId);
    if (!gameId) {
      return socket.emit('game:noActiveGame');
    }

    const game = activeGames.get(gameId);
    if (!game || game.state === GameState.FINISHED) {
      return socket.emit('game:noActiveGame');
    }

    // Cancel pending disconnect timer
    const dcKey = `${gameId}:${userId}`;
    const dcTimer = disconnectTimers.get(dcKey);
    if (dcTimer) {
      clearTimeout(dcTimer);
      disconnectTimers.delete(dcKey);
    }

    const roomName = `game:${gameId}`;
    socket.join(roomName);
    socket.emit('game:reconnected', {
      gameId,
      snapshot: getGameSnapshot(game),
    });
  });

  // Undo last move
  socket.on('game:undoMove', () => {
    const gameId = playerGames.get(userId);
    if (!gameId) return;

    const game = activeGames.get(gameId);
    if (!game) return;

    const color = getPlayerColor(game, userId);
    if (!color || game.currentTurn !== color) return;

    const result = undoLastMove(game);
    if (result.success) {
      const roomName = `game:${gameId}`;
      io.to(roomName).emit('game:moveUndone', {
        undoneMove: result.undoneMove,
        remainingDice: result.remainingDice,
        snapshot: getGameSnapshot(game),
      });
    } else {
      socket.emit('game:error', { message: result.error });
    }
  });

  // Emoji reactions
  socket.on('game:emoji', (data) => {
    if (!socket.rateLimitCheck('game:emoji')) return;

    const gameId = playerGames.get(userId);
    if (!gameId) return;

    const game = activeGames.get(gameId);
    if (!game) return;

    const emoji = typeof data?.emoji === 'string' ? data.emoji : '';
    if (!ALLOWED_EMOJIS.includes(emoji)) return;

    const color = getPlayerColor(game, userId);
    const roomName = `game:${gameId}`;
    io.to(roomName).emit('game:emoji', {
      emoji,
      from: color || '',
    });
  });

  // Handle disconnect - start reconnect window
  socket.on('disconnect', () => {
    const gameId = playerGames.get(userId);
    if (!gameId) return;

    const game = activeGames.get(gameId);
    if (!game || game.state !== GameState.PLAYING) return;

    const roomName = `game:${gameId}`;
    io.to(roomName).emit('game:playerDisconnected', { userId });

    // Store disconnect timer so reconnect can cancel it
    const dcKey = `${gameId}:${userId}`;
    const timerId = setTimeout(() => {
      disconnectTimers.delete(dcKey);

      // Player did not reconnect
      if (game.state === GameState.PLAYING) {
        const color = getPlayerColor(game, userId);
        if (color) {
          const { disconnectGame } = require('../../game/engine');
          const result = disconnectGame(game, color);
          if (result.success) {
            clearTurnTimer(gameId);
            handleGameEnd(io, gameId, game, result);
          }
        }
      }
    }, config.game.reconnectWindowSeconds * 1000);

    disconnectTimers.set(dcKey, timerId);
  });
}

/**
 * Start turn timer for the current player.
 */
function startTurnTimer(io, gameId, game) {
  clearTurnTimer(gameId);

  // Capture current turnId to prevent race conditions
  const currentTurnId = game.turnId || 0;

  const timerId = setTimeout(() => {
    // Guard: only fire if game is still playing AND this is still the same turn
    if (game.state !== GameState.PLAYING) return;
    if ((game.turnId || 0) !== currentTurnId) return;

    const { timeoutGame } = require('../../game/engine');
    const result = timeoutGame(game);
    if (result.success) {
      handleGameEnd(io, gameId, game, result);
    }
  }, config.game.moveTimerSeconds * 1000);

  turnTimers.set(gameId, timerId);

  // Broadcast timer start to clients
  const roomName = `game:${gameId}`;
  io.to(roomName).emit('game:timerStart', {
    seconds: config.game.moveTimerSeconds,
    currentTurn: game.currentTurn,
  });
}

/**
 * Clear turn timer.
 */
function clearTurnTimer(gameId) {
  const timerId = turnTimers.get(gameId);
  if (timerId) {
    clearTimeout(timerId);
    turnTimers.delete(gameId);
  }
}

/**
 * Handle game end: update DB, calculate ELO, notify players.
 */
async function handleGameEnd(io, gameId, game, result) {
  const roomName = `game:${gameId}`;

  try {
    // Get player ratings
    const whiteProfile = await userService.getProfile(game.whitePlayerId);
    const blackProfile = await userService.getProfile(game.blackPlayerId);

    // Determine winner/loser
    const winnerId = result.winner === 'W' ? game.whitePlayerId : game.blackPlayerId;
    const loserId = result.winner === 'W' ? game.blackPlayerId : game.whitePlayerId;
    const winnerRating = result.winner === 'W' ? whiteProfile.elo_rating : blackProfile.elo_rating;
    const loserRating = result.winner === 'W' ? blackProfile.elo_rating : whiteProfile.elo_rating;

    // Calculate ELO changes
    const eloChange = calculateEloChange(winnerRating, loserRating, result.resultType);

    // Update DB
    await gameService.finishGameRecord(
      gameId, winnerId, result.resultType,
      serializeBoard(game.board),
      {
        white: result.winner === 'W' ? eloChange.winnerChange : eloChange.loserChange,
        black: result.winner === 'B' ? eloChange.winnerChange : eloChange.loserChange,
      },
      game.moveNumber,
    );

    // Save all move history
    for (const move of game.moveHistory) {
      const moveUserId = move.player === 'W' ? game.whitePlayerId : game.blackPlayerId;
      await gameService.saveGameMove(gameId, moveUserId, move.moveNumber, move.dice, move.moves, move.boardAfter);
    }

    // Update user stats and ELO
    await userService.updateGameStats(winnerId, true, result.resultType);
    await userService.updateGameStats(loserId, false, result.resultType);
    await userService.updateEloRating(winnerId, eloChange.winnerNewRating);
    await userService.updateEloRating(loserId, eloChange.loserNewRating);

    // Notify players
    io.to(roomName).emit('game:finished', {
      winner: result.winner,
      resultType: result.resultType,
      eloChanges: {
        white: result.winner === 'W' ? eloChange.winnerChange : eloChange.loserChange,
        black: result.winner === 'B' ? eloChange.winnerChange : eloChange.loserChange,
      },
      snapshot: getGameSnapshot(game),
    });
  } catch (err) {
    logger.error('GameEnd', 'Error saving game result', err);
    io.to(roomName).emit('game:finished', {
      winner: result.winner,
      resultType: result.resultType,
      snapshot: getGameSnapshot(game),
    });
  }

  // Cleanup
  playerGames.delete(game.whitePlayerId);
  playerGames.delete(game.blackPlayerId);
  activeGames.delete(gameId);

  // Clean up Redis state
  stateStore.deleteGame(gameId);
  stateStore.deletePlayerGame(game.whitePlayerId);
  stateStore.deletePlayerGame(game.blackPlayerId);
}

module.exports = { gameHandler, validateMoveData };
