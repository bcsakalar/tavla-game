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
const { activeGames, playerGames } = require('./lobby');
const config = require('../../config');

// Turn timers: Map<gameId, timeoutId>
const turnTimers = new Map();

function gameHandler(io, socket) {
  const userId = socket.user.id;

  // Roll dice
  socket.on('game:rollDice', () => {
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
    const gameId = playerGames.get(userId);
    if (!gameId) return socket.emit('game:error', { message: 'Aktif oyun yok' });

    const game = activeGames.get(gameId);
    if (!game) return;

    const color = getPlayerColor(game, userId);
    if (!color) return;

    // Calculate dieValue from coordinates if not provided
    let dieValue = moveData.dieValue;
    if (dieValue === undefined || dieValue === null) {
      if (moveData.from === 'bar') {
        dieValue = color === 'W' ? (24 - moveData.to) : (moveData.to + 1);
      } else if (moveData.to === 'off') {
        dieValue = color === 'W' ? (moveData.from + 1) : (24 - moveData.from);
      } else {
        dieValue = color === 'W' ? (moveData.from - moveData.to) : (moveData.to - moveData.from);
      }
    }

    const move = {
      from: moveData.from,
      to: moveData.to,
      dieValue,
      isHit: false, // Will be determined by the engine
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
      console.error('[Chat] Error:', err.message);
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
    const gameId = playerGames.get(userId);
    if (!gameId) return;

    const game = activeGames.get(gameId);
    if (!game) return;

    const allowedEmojis = ['👍', '😂', '😮', '😡', '🎉', '🤔'];
    const emoji = typeof data?.emoji === 'string' ? data.emoji : '';
    if (!allowedEmojis.includes(emoji)) return;

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

    // Give time to reconnect
    setTimeout(() => {
      // Check if player reconnected
      const sockets = io.sockets.adapter.rooms.get(roomName);
      if (sockets) {
        for (const sid of sockets) {
          const s = io.sockets.sockets.get(sid);
          if (s && s.user && s.user.id === userId) {
            return; // Player reconnected
          }
        }
      }

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
    console.error('[GameEnd] Error:', err.message);
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
}

module.exports = { gameHandler };
