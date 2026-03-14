/**
 * Tavla (Backgammon) Move Validation & Generation
 *
 * Rules enforced:
 * 1. Pieces on bar MUST re-enter before any other move.
 * 2. A piece can move to a point that is: empty, has own pieces, or has exactly 1 opponent (blot → hit).
 * 3. Both dice must be used if possible. If only one can be used, the higher must be used.
 * 4. Doubles = 4 moves of that value.
 * 5. Bearing off: all 15 pieces must be in home board. Can bear off exact, or use higher die from highest occupied.
 */

const {
  WHITE, BLACK, TOTAL_POINTS,
  cloneBoard, isPointOpen, getHomeBoardRange,
  allInHomeBoard, getBarEntryStart, getTargetIndex,
  pointNumberForPlayer, highestOccupiedInHome, opponent,
} = require('./board');

/**
 * Special move indicators.
 * 'bar' = moving from bar, 'off' = bearing off
 */
const BAR = 'bar';
const OFF = 'off';

/**
 * Get all valid single moves for one die value.
 * Returns array of { from, to, dieValue, isHit }
 */
function getSingleMoves(board, player, dieValue) {
  const moves = [];

  // Must enter from bar first
  if (board.bar[player] > 0) {
    const entryStart = getBarEntryStart(player);
    const targetIndex = getTargetIndex(entryStart, dieValue - 1, player);
    // For bar entry: White enters at 24-die (index 24-die), Black at die-1
    const barTarget = player === WHITE ? (24 - dieValue) : (dieValue - 1);

    if (barTarget >= 0 && barTarget < TOTAL_POINTS && isPointOpen(board, barTarget, player)) {
      const isHit = board.points[barTarget].length === 1 && board.points[barTarget][0] === opponent(player);
      moves.push({ from: BAR, to: barTarget, dieValue, isHit });
    }
    return moves; // Can't move anything else while on bar
  }

  // Check bearing off
  const canBearOff = allInHomeBoard(board, player);
  const home = getHomeBoardRange(player);

  for (let i = 0; i < TOTAL_POINTS; i++) {
    const point = board.points[i];
    if (point.length === 0 || point[0] !== player) continue;

    const targetIndex = getTargetIndex(i, dieValue, player);

    // Regular move (within board)
    if (targetIndex >= 0 && targetIndex < TOTAL_POINTS) {
      if (isPointOpen(board, targetIndex, player)) {
        const isHit = board.points[targetIndex].length === 1 && board.points[targetIndex][0] === opponent(player);
        moves.push({ from: i, to: targetIndex, dieValue, isHit });
      }
    }

    // Bearing off
    if (canBearOff) {
      const pointNum = pointNumberForPlayer(i, player);

      if (pointNum === dieValue) {
        // Exact bear off
        moves.push({ from: i, to: OFF, dieValue, isHit: false });
      } else if (pointNum < dieValue) {
        // Can bear off with higher die only if no pieces on higher points
        const highest = highestOccupiedInHome(board, player);
        if (highest === i) {
          moves.push({ from: i, to: OFF, dieValue, isHit: false });
        }
      }
    }
  }

  return moves;
}

/**
 * Apply a single move to a board (mutates a clone).
 * Returns the new board state.
 */
function applySingleMove(board, player, move) {
  const newBoard = cloneBoard(board);

  // Remove piece from source
  if (move.from === BAR) {
    newBoard.bar[player]--;
  } else {
    newBoard.points[move.from].pop();
  }

  // Place piece at destination
  if (move.to === OFF) {
    newBoard.borneOff[player]++;
  } else {
    // Check for hit (blot)
    if (move.isHit) {
      const hitPlayer = opponent(player);
      newBoard.points[move.to] = [];
      newBoard.bar[hitPlayer]++;
    }
    newBoard.points[move.to].push(player);
  }

  return newBoard;
}

/**
 * Recursively find all possible move sequences using the given remaining dice.
 * Returns array of { moves: [...], board: finalBoard }
 */
function findAllMoveSequences(board, player, remainingDice, movesSoFar) {
  if (remainingDice.length === 0) {
    return [{ moves: [...movesSoFar], board: cloneBoard(board) }];
  }

  const results = [];
  const triedDice = new Set();

  for (let i = 0; i < remainingDice.length; i++) {
    const dieValue = remainingDice[i];
    if (triedDice.has(dieValue)) continue;
    triedDice.add(dieValue);

    const singleMoves = getSingleMoves(board, player, dieValue);

    for (const move of singleMoves) {
      const newBoard = applySingleMove(board, player, move);
      const newRemaining = [...remainingDice];
      newRemaining.splice(i, 1);

      const subResults = findAllMoveSequences(newBoard, player, newRemaining, [...movesSoFar, move]);
      results.push(...subResults);
    }
  }

  // If no moves possible with remaining dice, return current state
  if (results.length === 0) {
    results.push({ moves: [...movesSoFar], board: cloneBoard(board) });
  }

  return results;
}

/**
 * Get all valid complete move sequences for a player's turn.
 * Enforces: use both dice if possible, else use higher die.
 * Returns array of { moves: [...], board: finalBoard }
 */
function getValidMoveSequences(board, player, dice) {
  const { expandDice } = require('./dice');
  const expandedDice = expandDice(dice);
  const allSequences = findAllMoveSequences(board, player, expandedDice, []);

  if (allSequences.length === 0) return [];

  // Find maximum number of dice used in any sequence
  const maxMoves = Math.max(...allSequences.map((s) => s.moves.length));

  // Filter: must use maximum number of dice
  let bestSequences = allSequences.filter((s) => s.moves.length === maxMoves);

  // If only one die can be used and dice are different, must use the higher one
  if (maxMoves === 1 && dice[0] !== dice[1]) {
    const higherDie = Math.max(dice[0], dice[1]);
    const withHigher = bestSequences.filter((s) => s.moves[0].dieValue === higherDie);
    if (withHigher.length > 0) {
      bestSequences = withHigher;
    }
  }

  return bestSequences;
}

/**
 * Get valid moves for a specific die value given current board state.
 * For UI: which pieces can move with this die?
 */
function getMovesForDie(board, player, dieValue) {
  return getSingleMoves(board, player, dieValue);
}

/**
 * Validate if a specific move is legal within any valid move sequence.
 */
function isMoveValid(board, player, dice, move, previousMoves) {
  const { expandDice } = require('./dice');
  let expandedDice = expandDice(dice);

  // Remove dice used by previous moves
  for (const pm of previousMoves) {
    const idx = expandedDice.indexOf(pm.dieValue);
    if (idx !== -1) expandedDice.splice(idx, 1);
  }

  // board already reflects previousMoves (mutated by engine.makeMove),
  // so we just clone it without replaying.
  let currentBoard = cloneBoard(board);

  // Check if the proposed move is in valid single moves
  const validSingle = getSingleMoves(currentBoard, player, move.dieValue);
  const isValidSingle = validSingle.some(
    (m) => m.from === move.from && m.to === move.to && m.dieValue === move.dieValue
  );

  if (!isValidSingle) return false;

  // Check that this move doesn't prevent using the maximum number of dice
  const afterMove = applySingleMove(currentBoard, player, move);
  const remainingAfter = [...expandedDice];
  const usedIdx = remainingAfter.indexOf(move.dieValue);
  if (usedIdx !== -1) remainingAfter.splice(usedIdx, 1);

  // Check if remaining dice can be used
  const futureSequences = findAllMoveSequences(afterMove, player, remainingAfter, []);
  const maxFutureMoves = Math.max(0, ...futureSequences.map((s) => s.moves.length));

  // Also check max possible without this specific move
  const allRemaining = [...expandedDice];
  const allSequences = findAllMoveSequences(currentBoard, player, allRemaining, []);
  const maxTotal = Math.max(0, ...allSequences.map((s) => s.moves.length));

  // This move is valid if using it + future = max possible total
  return (1 + maxFutureMoves) >= maxTotal;
}

module.exports = {
  BAR,
  OFF,
  getSingleMoves,
  applySingleMove,
  findAllMoveSequences,
  getValidMoveSequences,
  getMovesForDie,
  isMoveValid,
};
