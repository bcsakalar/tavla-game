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
 * Apply a move in-place (mutates the board directly). Returns undo info.
 * Used by optimized findAllMoveSequences to avoid cloneBoard overhead.
 */
function applyMoveInPlace(board, player, move) {
  const undo = { from: move.from, to: move.to, isHit: move.isHit, hitPlayer: null, removedPiece: null };

  // Remove piece from source
  if (move.from === BAR) {
    board.bar[player]--;
  } else {
    board.points[move.from].pop();
  }

  // Place piece at destination
  if (move.to === OFF) {
    board.borneOff[player]++;
  } else {
    if (move.isHit) {
      const hitPlayer = opponent(player);
      undo.hitPlayer = hitPlayer;
      undo.removedPiece = board.points[move.to][0];
      board.points[move.to] = [player];
      board.bar[hitPlayer]++;
    } else {
      board.points[move.to].push(player);
    }
  }

  return undo;
}

/**
 * Undo a move in-place (reverses applyMoveInPlace).
 */
function undoMoveInPlace(board, player, move, undo) {
  // Undo destination
  if (move.to === OFF) {
    board.borneOff[player]--;
  } else {
    if (undo.isHit && undo.hitPlayer) {
      board.bar[undo.hitPlayer]--;
      board.points[move.to] = [undo.removedPiece];
    } else {
      board.points[move.to].pop();
    }
  }

  // Undo source
  if (move.from === BAR) {
    board.bar[player]++;
  } else {
    board.points[move.from].push(player);
  }
}

/**
 * Recursively find all possible move sequences using the given remaining dice.
 * Optimized: uses in-place board mutation with undo to avoid cloneBoard overhead.
 * Tracks maximum moves found for early termination.
 * Returns array of { moves: [...], board: finalBoard }
 */
function findAllMoveSequences(board, player, remainingDice, movesSoFar) {
  // Delegate to optimized internal function that tracks max depth
  const context = { maxMovesFound: 0 };
  const rawResults = [];
  _findSequencesOptimized(board, player, remainingDice, movesSoFar || [], rawResults, context);

  // Convert raw results (which only have moves) to include board snapshots
  // by replaying moves on the original board (only for final results)
  if (rawResults.length === 0) {
    return [{ moves: movesSoFar ? [...movesSoFar] : [], board: cloneBoard(board) }];
  }

  return rawResults.map((r) => {
    // Replay moves to get final board state
    let b = cloneBoard(board);
    // Skip movesSoFar prefix since those are already applied on the input board
    for (const m of r.moves) {
      b = applySingleMove(b, player, m);
    }
    return { moves: r.moves, board: b };
  });
}

/**
 * Internal optimized recursive search. Mutates board in-place and undoes.
 * Results are stored as move arrays only (boards computed lazily).
 */
function _findSequencesOptimized(board, player, remainingDice, movesSoFar, results, context) {
  if (remainingDice.length === 0) {
    results.push({ moves: [...movesSoFar] });
    context.maxMovesFound = Math.max(context.maxMovesFound, movesSoFar.length);
    return;
  }

  // Early termination: if we already found sequences using all dice, and current
  // branch can't possibly reach that (remaining + done < max found), skip
  const maxPossible = movesSoFar.length + remainingDice.length;
  if (context.maxMovesFound > 0 && maxPossible < context.maxMovesFound) {
    return;
  }

  let anyMoveFound = false;
  const triedDice = new Set();

  for (let i = 0; i < remainingDice.length; i++) {
    const dieValue = remainingDice[i];
    if (triedDice.has(dieValue)) continue;
    triedDice.add(dieValue);

    const singleMoves = getSingleMoves(board, player, dieValue);

    // Deduplicate moves that lead to identical board positions
    const seenTargets = new Set();

    for (const move of singleMoves) {
      // Dedup key: from-to is sufficient for same die value
      const moveKey = `${move.from}-${move.to}`;
      if (seenTargets.has(moveKey)) continue;
      seenTargets.add(moveKey);

      anyMoveFound = true;

      // Apply move in-place
      const undo = applyMoveInPlace(board, player, move);

      // Build new remaining dice
      const newRemaining = [...remainingDice];
      newRemaining.splice(i, 1);

      movesSoFar.push(move);
      _findSequencesOptimized(board, player, newRemaining, movesSoFar, results, context);
      movesSoFar.pop();

      // Undo move in-place
      undoMoveInPlace(board, player, move, undo);
    }
  }

  // If no moves possible with remaining dice, record current state
  if (!anyMoveFound) {
    results.push({ moves: [...movesSoFar] });
    context.maxMovesFound = Math.max(context.maxMovesFound, movesSoFar.length);
  }
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
 * Get the maximum number of dice that can be used from a given board state.
 * Lightweight alternative to getValidMoveSequences — only computes the count.
 * Used by isMoveValid to avoid redundant full tree searches.
 */
function getMaxDiceUsable(board, player, remainingDice) {
  let maxMoves = 0;

  function search(board, remaining, depth) {
    // Early termination: if depth + remaining can't beat max, return
    if (depth + remaining.length <= maxMoves) return;

    // If all dice used, update max
    if (remaining.length === 0) {
      maxMoves = Math.max(maxMoves, depth);
      return;
    }

    let anyMove = false;
    const triedDice = new Set();

    for (let i = 0; i < remaining.length; i++) {
      const dieValue = remaining[i];
      if (triedDice.has(dieValue)) continue;
      triedDice.add(dieValue);

      const singleMoves = getSingleMoves(board, player, dieValue);
      const seenTargets = new Set();

      for (const move of singleMoves) {
        const moveKey = `${move.from}-${move.to}`;
        if (seenTargets.has(moveKey)) continue;
        seenTargets.add(moveKey);

        anyMove = true;
        const undo = applyMoveInPlace(board, player, move);
        const newRemaining = [...remaining];
        newRemaining.splice(i, 1);
        search(board, newRemaining, depth + 1);
        undoMoveInPlace(board, player, move, undo);

        // Early exit: if we've reached the theoretical max, stop searching
        if (maxMoves === depth + remaining.length) return;
      }
    }

    if (!anyMove) {
      maxMoves = Math.max(maxMoves, depth);
    }
  }

  search(board, remainingDice, 0);
  return maxMoves;
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
 * Optimized: uses getMaxDiceUsable instead of full tree enumeration.
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
  // Use lightweight getMaxDiceUsable instead of full findAllMoveSequences
  const remainingAfterMove = [...expandedDice];
  const usedIdx = remainingAfterMove.indexOf(move.dieValue);
  if (usedIdx !== -1) remainingAfterMove.splice(usedIdx, 1);

  // Get max dice usable after this move
  const afterBoard = applySingleMove(currentBoard, player, move);
  const maxFutureMoves = getMaxDiceUsable(afterBoard, player, remainingAfterMove);

  // Get max dice usable overall (from current state)
  const maxTotal = getMaxDiceUsable(currentBoard, player, [...expandedDice]);

  // This move is valid if using it + future = max possible total
  return (1 + maxFutureMoves) >= maxTotal;
}

module.exports = {
  BAR,
  OFF,
  getSingleMoves,
  applySingleMove,
  applyMoveInPlace,
  undoMoveInPlace,
  findAllMoveSequences,
  getValidMoveSequences,
  getMaxDiceUsable,
  getMovesForDie,
  isMoveValid,
};
