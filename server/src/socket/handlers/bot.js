/**
 * Bot game handler — allows playing against AI for practice.
 *
 * Events:
 *   bot:startGame     → start a game against bot { difficulty: 'easy'|'medium'|'hard' }
 *   bot:rollDice      → roll dice (triggers bot response if needed)
 *   bot:move          → make a move
 *   bot:undoMove      → undo last move
 *   bot:endTurn       → end turn (triggers bot turn)
 *   bot:resign        → resign from bot game
 */

const {
  createGame, startGame, rollTurnDice, makeMove,
  getGameSnapshot, getPlayerColor, GameState,
  isTurnComplete, switchTurn, recordTurnMoves,
  resignGame, undoLastMove, TurnPhase,
} = require('../../game/engine');
const { chooseMoves } = require('../../game/bot');
const { rollDice, expandDice } = require('../../game/dice');
const config = require('../../config');
const { validateMoveData } = require('./game');

// Bot games: Map<userId, { game, difficulty, turnTimer }>
const botGames = new Map();

function botHandler(io, socket) {
  const userId = socket.user.id;

  // Start bot game
  socket.on('bot:startGame', (data) => {
    // Clean up existing bot game if any
    if (botGames.has(userId)) {
      const existing = botGames.get(userId);
      if (existing.turnTimer) clearTimeout(existing.turnTimer);
      botGames.delete(userId);
    }

    const difficulty = ['easy', 'medium', 'hard'].includes(data?.difficulty)
      ? data.difficulty
      : 'easy';

    // Player is always white, bot is always black
    const game = createGame(userId, -1); // -1 = bot userId
    const startResult = startGame(game);

    const session = { game, difficulty, turnTimer: null };
    botGames.set(userId, session);

    socket.emit('bot:gameStarted', {
      difficulty,
      ...startResult,
      snapshot: getGameSnapshot(game),
    });

    // If bot goes first (firstPlayer === 'B'), play bot turn
    if (startResult.firstPlayer === 'B' && !startResult.autoSkip) {
      setTimeout(() => playBotTurn(io, socket, userId, true), 1500);
    }
  });

  // Player rolls dice
  socket.on('bot:rollDice', () => {
    if (!socket.rateLimitCheck('bot:rollDice')) return;

    const session = botGames.get(userId);
    if (!session) return socket.emit('game:error', { message: 'Bot oyunu yok' });

    const { game } = session;
    const color = getPlayerColor(game, userId);
    if (!color || game.currentTurn !== color) {
      return socket.emit('game:error', { message: 'Sıra sizde değil' });
    }

    const result = rollTurnDice(game);
    if (!result.success) {
      return socket.emit('game:error', { message: result.error });
    }

    socket.emit('bot:diceRolled', {
      dice: result.dice,
      autoSkip: result.autoSkip || false,
      snapshot: getGameSnapshot(game),
    });

    if (result.autoSkip) {
      // Player had no moves, now it's bot's turn
      setTimeout(() => playBotTurn(io, socket, userId), 1000);
    }
  });

  // Player makes a move
  socket.on('bot:move', (moveData) => {
    if (!socket.rateLimitCheck('bot:move')) return;

    const validated = validateMoveData(moveData);
    if (!validated) return socket.emit('game:error', { message: 'Geçersiz hamle verisi' });

    const session = botGames.get(userId);
    if (!session) return;

    const { game } = session;
    const color = getPlayerColor(game, userId);
    if (!color) return;

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

    if (move.to !== 'off' && move.to >= 0 && move.to < 24) {
      const { opponent } = require('../../game/board');
      const targetPoint = game.board.points[move.to];
      move.isHit = targetPoint.length === 1 && targetPoint[0] === opponent(color);
    }

    const result = makeMove(game, color, move);
    if (!result.success) {
      return socket.emit('game:error', { message: result.error });
    }

    if (result.gameOver) {
      socket.emit('bot:gameFinished', {
        winner: result.winner,
        resultType: result.resultType,
        snapshot: getGameSnapshot(game),
      });
      botGames.delete(userId);
    } else if (result.turnOver) {
      socket.emit('bot:moved', {
        move: moveData,
        turnOver: true,
        snapshot: getGameSnapshot(game),
      });
      // Bot's turn
      setTimeout(() => playBotTurn(io, socket, userId), 1000);
    } else {
      socket.emit('bot:moved', {
        move: moveData,
        turnOver: false,
        remainingDice: result.remainingDice,
        snapshot: getGameSnapshot(game),
      });
    }
  });

  // Undo last move
  socket.on('bot:undoMove', () => {
    const session = botGames.get(userId);
    if (!session) return;

    const { game } = session;
    const color = getPlayerColor(game, userId);
    if (!color || game.currentTurn !== color) return;

    const result = undoLastMove(game);
    if (result.success) {
      socket.emit('bot:moveUndone', {
        undoneMove: result.undoneMove,
        remainingDice: result.remainingDice,
        snapshot: getGameSnapshot(game),
      });
    }
  });

  // End turn
  socket.on('bot:endTurn', () => {
    const session = botGames.get(userId);
    if (!session) return;

    const { game } = session;
    const color = getPlayerColor(game, userId);
    if (!color || game.currentTurn !== color) return;

    if (isTurnComplete(game)) {
      if (game.movesThisTurn.length > 0) {
        recordTurnMoves(game);
      }
      switchTurn(game);
      socket.emit('bot:turnEnded', {
        snapshot: getGameSnapshot(game),
      });
      // Bot's turn
      setTimeout(() => playBotTurn(io, socket, userId), 1000);
    }
  });

  // Resign
  socket.on('bot:resign', () => {
    const session = botGames.get(userId);
    if (!session) return;

    const { game } = session;
    const color = getPlayerColor(game, userId);
    if (!color) return;

    resignGame(game, color);
    socket.emit('bot:gameFinished', {
      winner: color === 'W' ? 'B' : 'W',
      resultType: 'resign',
      snapshot: getGameSnapshot(game),
    });
    botGames.delete(userId);
  });

  // Cleanup on disconnect
  socket.on('disconnect', () => {
    const session = botGames.get(userId);
    if (session) {
      if (session.turnTimer) clearTimeout(session.turnTimer);
      botGames.delete(userId);
    }
  });
}

/**
 * Execute bot's turn: roll dice, choose moves, apply them with delays.
 * @param {boolean} isFirstTurn - If true, dice are already rolled by startGame
 */
async function playBotTurn(io, socket, userId, isFirstTurn = false) {
  const session = botGames.get(userId);
  if (!session) return;

  const { game, difficulty } = session;
  if (game.state !== GameState.PLAYING) return;
  if (game.currentTurn !== 'B') return; // Bot is always Black

  let dice;

  if (isFirstTurn && game.turnPhase === TurnPhase.MOVING && game.dice) {
    // First turn — dice already rolled by startGame
    dice = game.dice;
    socket.emit('bot:diceRolled', {
      dice,
      autoSkip: false,
      isBot: true,
      snapshot: getGameSnapshot(game),
    });
  } else {
    // Normal turn — roll dice
    const rollResult = rollTurnDice(game);
    if (!rollResult.success) return;
    dice = rollResult.dice;

    socket.emit('bot:diceRolled', {
      dice,
      autoSkip: rollResult.autoSkip || false,
      isBot: true,
      snapshot: getGameSnapshot(game),
    });

    if (rollResult.autoSkip) {
      // Bot has no valid moves, turn already switched
      socket.emit('bot:turnEnded', {
        snapshot: getGameSnapshot(game),
      });
      return;
    }
  }

  // Choose moves with AI
  const moves = chooseMoves(game.board, 'B', dice, difficulty);

  if (moves.length === 0) {
    // No moves possible
    if (game.movesThisTurn.length > 0) recordTurnMoves(game);
    switchTurn(game);
    socket.emit('bot:turnEnded', { snapshot: getGameSnapshot(game) });
    return;
  }

  // Execute each move with delay for visual effect
  for (let i = 0; i < moves.length; i++) {
    // First move waits longer so player can see the dice
    const delay = i === 0 ? 1500 : 1200;
    await new Promise((resolve) => setTimeout(resolve, delay));

    if (!botGames.has(userId)) return; // Game was cancelled

    const move = moves[i];
    const result = makeMove(game, 'B', move);
    if (!result.success) break;

    if (result.gameOver) {
      socket.emit('bot:moved', {
        move,
        turnOver: true,
        isBot: true,
        snapshot: getGameSnapshot(game),
      });
      socket.emit('bot:gameFinished', {
        winner: result.winner,
        resultType: result.resultType,
        snapshot: getGameSnapshot(game),
      });
      botGames.delete(userId);
      return;
    }

    socket.emit('bot:moved', {
      move,
      turnOver: result.turnOver || false,
      isBot: true,
      remainingDice: result.remainingDice,
      snapshot: getGameSnapshot(game),
    });

    if (result.turnOver) {
      socket.emit('bot:turnEnded', { snapshot: getGameSnapshot(game) });
      return;
    }
  }

  // If there are remaining moves but bot ran out, end turn
  if (isTurnComplete(game)) {
    if (game.movesThisTurn.length > 0) recordTurnMoves(game);
    switchTurn(game);
    socket.emit('bot:turnEnded', { snapshot: getGameSnapshot(game) });
  }
}

module.exports = { botHandler, botGames };
