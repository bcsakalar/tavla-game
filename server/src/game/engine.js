/**
 * Tavla Game Engine — State Machine & Orchestrator
 *
 * Game States: WAITING → INITIAL_ROLL → PLAYING → FINISHED
 * Turn Flow:  ROLL_DICE → MAKE_MOVES → (next turn or finish)
 */

const { createInitialBoard, cloneBoard, serializeBoard, WHITE, BLACK, opponent } = require('./board');
const { rollDice, rollInitialDice, expandDice } = require('./dice');
const { getValidMoveSequences, applySingleMove, isMoveValid, BAR, OFF } = require('./moves');

// Game states
const GameState = {
  WAITING: 'waiting',
  INITIAL_ROLL: 'initial_roll',
  PLAYING: 'playing',
  FINISHED: 'finished',
};

// Turn phases
const TurnPhase = {
  ROLLING: 'rolling',
  MOVING: 'moving',
  WAITING: 'waiting', // waiting for opponent's turn
};

/**
 * Create a new game instance.
 */
function createGame(whitePlayerId, blackPlayerId) {
  return {
    state: GameState.WAITING,
    board: createInitialBoard(),
    whitePlayerId,
    blackPlayerId,
    currentTurn: null,       // 'W' or 'B'
    turnPhase: null,
    dice: null,
    expandedDice: null,
    movesThisTurn: [],
    diceUsed: [],
    moveHistory: [],         // All moves for the game
    moveNumber: 0,
    turnId: 0,               // Increments each turn, used to prevent timer race conditions
    winner: null,
    resultType: null,        // 'normal', 'gammon', 'backgammon'
    startedAt: null,
    finishedAt: null,
  };
}

/**
 * Start the game with initial dice roll to determine who goes first.
 */
function startGame(game) {
  if (game.state !== GameState.WAITING) {
    return { success: false, error: 'Game is not in waiting state' };
  }

  const { dice, firstPlayer } = rollInitialDice();

  game.state = GameState.PLAYING;
  game.currentTurn = firstPlayer;
  game.turnPhase = TurnPhase.MOVING;
  game.dice = dice;
  game.expandedDice = expandDice(dice);
  game.movesThisTurn = [];
  game.diceUsed = [];
  game.startedAt = new Date();

  // Save board state at turn start for undo support
  game._boardAtTurnStart = cloneBoard(game.board);

  // Check if first player has any valid moves
  const validSequences = getValidMoveSequences(game.board, firstPlayer, dice);
  const hasValidMoves = validSequences.some((s) => s.moves.length > 0);

  if (!hasValidMoves) {
    // No moves possible, auto-skip to next turn
    return {
      success: true,
      firstPlayer,
      dice,
      autoSkip: true,
      nextTurn: switchTurn(game),
    };
  }

  return {
    success: true,
    firstPlayer,
    dice,
    autoSkip: false,
  };
}

/**
 * Roll dice for the current player's turn.
 */
function rollTurnDice(game) {
  if (game.state !== GameState.PLAYING) {
    return { success: false, error: 'Game is not in playing state' };
  }
  if (game.turnPhase !== TurnPhase.ROLLING) {
    return { success: false, error: 'Not in rolling phase' };
  }

  const dice = rollDice();
  game.dice = dice;
  game.expandedDice = expandDice(dice);
  game.movesThisTurn = [];
  game.diceUsed = [];
  game.turnPhase = TurnPhase.MOVING;

  // Save board state at turn start for undo support
  game._boardAtTurnStart = cloneBoard(game.board);

  // Check if player has any valid moves
  const validSequences = getValidMoveSequences(game.board, game.currentTurn, dice);
  const hasValidMoves = validSequences.some((s) => s.moves.length > 0);

  if (!hasValidMoves) {
    return {
      success: true,
      dice,
      autoSkip: true,
      nextTurn: switchTurn(game),
    };
  }

  return { success: true, dice, autoSkip: false };
}

/**
 * Apply a single move within the current turn.
 */
function makeMove(game, player, move) {
  if (game.state !== GameState.PLAYING) {
    return { success: false, error: 'Game is not in playing state' };
  }
  if (game.currentTurn !== player) {
    return { success: false, error: 'Not your turn' };
  }
  if (game.turnPhase !== TurnPhase.MOVING) {
    return { success: false, error: 'Not in moving phase' };
  }

  // Check die is available
  const dieIdx = game.expandedDice.indexOf(move.dieValue);
  if (dieIdx === -1) {
    return { success: false, error: 'Die value not available' };
  }

  // Validate the move
  if (!isMoveValid(game.board, player, game.dice, move, game.movesThisTurn)) {
    return { success: false, error: 'Invalid move' };
  }

  // Apply the move
  game.board = applySingleMove(game.board, player, move);
  game.movesThisTurn.push(move);
  game.expandedDice.splice(dieIdx, 1);
  game.diceUsed.push(move.dieValue);

  // Check for win
  if (game.board.borneOff[player] === 15) {
    return finishGame(game, player);
  }

  // Check if turn is over (no more dice or no valid moves)
  const turnOver = isTurnComplete(game);

  if (turnOver) {
    // Record this turn's moves to history
    recordTurnMoves(game);

    return {
      success: true,
      turnOver: true,
      nextTurn: switchTurn(game),
    };
  }

  return {
    success: true,
    turnOver: false,
    remainingDice: [...game.expandedDice],
  };
}

/**
 * Check if the current turn is complete.
 */
function isTurnComplete(game) {
  if (game.expandedDice.length === 0) return true;

  // Check if there are any valid moves with remaining dice
  const remainingDice = [...game.expandedDice];
  let currentBoard = game.board;

  // Try each remaining die
  for (const die of remainingDice) {
    const { getSingleMoves } = require('./moves');
    const moves = getSingleMoves(currentBoard, game.currentTurn, die);
    if (moves.length > 0) return false;
  }

  return true;
}

/**
 * Record the moves of the completed turn.
 */
function recordTurnMoves(game) {
  game.moveNumber++;
  game.moveHistory.push({
    moveNumber: game.moveNumber,
    player: game.currentTurn,
    dice: [...game.dice],
    moves: game.movesThisTurn.map((m) => ({
      from: m.from,
      to: m.to,
      dieValue: m.dieValue,
      isHit: m.isHit,
    })),
    boardAfter: serializeBoard(game.board),
  });
}

/**
 * Switch turn to the other player.
 */
function switchTurn(game) {
  const nextPlayer = opponent(game.currentTurn);
  game.currentTurn = nextPlayer;
  game.turnPhase = TurnPhase.ROLLING;
  game.dice = null;
  game.expandedDice = null;
  game.movesThisTurn = [];
  game.diceUsed = [];
  game.turnId = (game.turnId || 0) + 1;

  return nextPlayer;
}

/**
 * Finish the game with a winner.
 */
function finishGame(game, winner) {
  recordTurnMoves(game);

  game.state = GameState.FINISHED;
  game.winner = winner;
  game.resultType = getResultType(game, winner);
  game.finishedAt = new Date();

  return {
    success: true,
    gameOver: true,
    winner,
    resultType: game.resultType,
  };
}

/**
 * Determine result type: normal, gammon, or backgammon.
 */
function getResultType(game, winner) {
  const loser = opponent(winner);

  // Loser has no pieces borne off = at minimum gammon
  if (game.board.borneOff[loser] === 0) {
    // Check backgammon: loser still has pieces on bar or in winner's home board
    const winnerHome = winner === WHITE
      ? { start: 0, end: 5 }
      : { start: 18, end: 23 };

    let inWinnerHome = game.board.bar[loser] > 0;
    if (!inWinnerHome) {
      for (let i = winnerHome.start; i <= winnerHome.end; i++) {
        if (game.board.points[i].length > 0 && game.board.points[i][0] === loser) {
          inWinnerHome = true;
          break;
        }
      }
    }

    return inWinnerHome ? 'backgammon' : 'gammon';
  }

  return 'normal';
}

/**
 * Handle player resignation.
 */
function resignGame(game, player) {
  if (game.state !== GameState.PLAYING) {
    return { success: false, error: 'Game is not in playing state' };
  }

  const winner = opponent(player);
  game.state = GameState.FINISHED;
  game.winner = winner;
  game.resultType = 'resign';
  game.finishedAt = new Date();

  return {
    success: true,
    gameOver: true,
    winner,
    resultType: 'resign',
  };
}

/**
 * Handle timeout (player ran out of move time).
 */
function timeoutGame(game) {
  if (game.state !== GameState.PLAYING) {
    return { success: false, error: 'Game is not in playing state' };
  }

  // Record any incomplete turn moves before finishing
  if (game.movesThisTurn && game.movesThisTurn.length > 0) {
    recordTurnMoves(game);
  }

  const winner = opponent(game.currentTurn);
  game.state = GameState.FINISHED;
  game.winner = winner;
  game.resultType = 'timeout';
  game.finishedAt = new Date();

  return {
    success: true,
    gameOver: true,
    winner,
    resultType: 'timeout',
  };
}

/**
 * Handle disconnect (player disconnected and didn't reconnect).
 */
function disconnectGame(game, disconnectedPlayer) {
  if (game.state !== GameState.PLAYING) {
    return { success: false, error: 'Game is not in playing state' };
  }

  // Record any incomplete turn moves before finishing
  if (game.movesThisTurn && game.movesThisTurn.length > 0) {
    recordTurnMoves(game);
  }

  const winner = opponent(disconnectedPlayer);
  game.state = GameState.FINISHED;
  game.winner = winner;
  game.resultType = 'disconnect';
  game.finishedAt = new Date();

  return {
    success: true,
    gameOver: true,
    winner,
    resultType: 'disconnect',
  };
}

/**
 * Get the current game state snapshot for sending to clients.
 */
function getGameSnapshot(game) {
  return {
    state: game.state,
    board: serializeBoard(game.board),
    currentTurn: game.currentTurn,
    turnPhase: game.turnPhase,
    dice: game.dice,
    remainingDice: game.expandedDice ? [...game.expandedDice] : null,
    movesThisTurn: game.movesThisTurn,
    moveNumber: game.moveNumber,
    turnId: game.turnId || 0,
    winner: game.winner,
    resultType: game.resultType,
    whitePlayerId: game.whitePlayerId,
    blackPlayerId: game.blackPlayerId,
    borneOff: { ...game.board.borneOff },
    bar: { ...game.board.bar },
    moveTimerSeconds: require('../config').game.moveTimerSeconds,
  };
}

/**
 * Get the player color by user ID.
 */
function getPlayerColor(game, userId) {
  if (game.whitePlayerId === userId) return WHITE;
  if (game.blackPlayerId === userId) return BLACK;
  return null;
}

/**
 * Undo the last move within the current turn.
 * Returns the undone move or null if no moves to undo.
 */
function undoLastMove(game) {
  if (game.state !== GameState.PLAYING) {
    return { success: false, error: 'Game is not in playing state' };
  }
  if (game.turnPhase !== TurnPhase.MOVING) {
    return { success: false, error: 'Not in moving phase' };
  }
  if (game.movesThisTurn.length === 0) {
    return { success: false, error: 'No moves to undo' };
  }

  // We need to replay all moves except the last one from the board state at turn start
  // Store the board snapshot at turn start for undo support
  if (!game._boardAtTurnStart) {
    return { success: false, error: 'Cannot undo' };
  }

  const undoneMoves = game.movesThisTurn.pop();
  const usedDieIdx = game.diceUsed.lastIndexOf(undoneMoves.dieValue);
  if (usedDieIdx !== -1) game.diceUsed.splice(usedDieIdx, 1);
  game.expandedDice.push(undoneMoves.dieValue);

  // Rebuild board from turn start
  let currentBoard = cloneBoard(game._boardAtTurnStart);
  for (const move of game.movesThisTurn) {
    currentBoard = applySingleMove(currentBoard, game.currentTurn, move);
  }
  game.board = currentBoard;

  return {
    success: true,
    undoneMove: undoneMoves,
    remainingDice: [...game.expandedDice],
  };
}

module.exports = {
  GameState,
  TurnPhase,
  createGame,
  startGame,
  rollTurnDice,
  makeMove,
  isTurnComplete,
  recordTurnMoves,
  finishGame,
  getResultType,
  resignGame,
  timeoutGame,
  disconnectGame,
  undoLastMove,
  getGameSnapshot,
  getPlayerColor,
  switchTurn,
};
