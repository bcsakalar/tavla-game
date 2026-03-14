/**
 * Tavla (Backgammon) Board State
 *
 * Board representation:
 * - 24 points (1-24), each holding an array of pieces
 * - Point 1-6: White's home board
 * - Point 19-24: Black's home board
 * - White moves from 24 → 1, Black moves from 1 → 24
 *
 * Piece values: 'W' = White, 'B' = Black
 *
 * Starting position (standard backgammon):
 *   White: 2 on point 24, 5 on point 13, 3 on point 8, 5 on point 6
 *   Black: 2 on point 1,  5 on point 12, 3 on point 17, 5 on point 19
 */

const WHITE = 'W';
const BLACK = 'B';
const TOTAL_PIECES = 15;
const TOTAL_POINTS = 24;

function createInitialBoard() {
  const points = new Array(TOTAL_POINTS).fill(null).map(() => []);

  // White pieces (moves 24 → 1)
  points[23] = [WHITE, WHITE];             // Point 24: 2 white
  points[12] = [WHITE, WHITE, WHITE, WHITE, WHITE]; // Point 13: 5 white
  points[7]  = [WHITE, WHITE, WHITE];      // Point 8:  3 white
  points[5]  = [WHITE, WHITE, WHITE, WHITE, WHITE]; // Point 6:  5 white

  // Black pieces (moves 1 → 24)
  points[0]  = [BLACK, BLACK];             // Point 1:  2 black
  points[11] = [BLACK, BLACK, BLACK, BLACK, BLACK]; // Point 12: 5 black
  points[16] = [BLACK, BLACK, BLACK];      // Point 17: 3 black
  points[18] = [BLACK, BLACK, BLACK, BLACK, BLACK]; // Point 19: 5 black

  return {
    points,
    bar: { [WHITE]: 0, [BLACK]: 0 },
    borneOff: { [WHITE]: 0, [BLACK]: 0 },
  };
}

function cloneBoard(board) {
  return {
    points: board.points.map((p) => [...p]),
    bar: { ...board.bar },
    borneOff: { ...board.borneOff },
  };
}

function serializeBoard(board) {
  return {
    points: board.points.map((p) => ({
      count: p.length,
      player: p.length > 0 ? p[0] : null,
    })),
    bar: { ...board.bar },
    borneOff: { ...board.borneOff },
  };
}

function deserializeBoard(data) {
  const points = data.points.map((p) => {
    if (p.count === 0 || !p.player) return [];
    return new Array(p.count).fill(p.player);
  });
  return {
    points,
    bar: { ...data.bar },
    borneOff: { ...data.borneOff },
  };
}

/**
 * Get the direction a player moves.
 * White: high → low (24 → 1), i.e., index decreases
 * Black: low → high (1 → 24), i.e., index increases
 */
function getMoveDirection(player) {
  return player === WHITE ? -1 : 1;
}

/**
 * Get the home board range for a player (indices 0-23).
 * White home: points 1-6 → indices 0-5
 * Black home: points 19-24 → indices 18-23
 */
function getHomeBoardRange(player) {
  return player === WHITE
    ? { start: 0, end: 5 }
    : { start: 18, end: 23 };
}

/**
 * Get the bar entry point index for a player.
 * White enters from opponent's home (point 24 side) → index 23
 * Black enters from opponent's home (point 1 side) → index 0
 */
function getBarEntryStart(player) {
  return player === WHITE ? 23 : 0;
}

/**
 * Count all pieces of a player on the board (on points, not bar or borne off).
 */
function countOnBoard(board, player) {
  let count = 0;
  for (const point of board.points) {
    for (const piece of point) {
      if (piece === player) count++;
    }
  }
  return count;
}

/**
 * Check if all of a player's pieces are in their home board.
 */
function allInHomeBoard(board, player) {
  if (board.bar[player] > 0) return false;

  const home = getHomeBoardRange(player);
  for (let i = 0; i < TOTAL_POINTS; i++) {
    if (i >= home.start && i <= home.end) continue;
    for (const piece of board.points[i]) {
      if (piece === player) return false;
    }
  }
  return true;
}

/**
 * Check if a point is open for a player to land on.
 * A point is open if: empty, has own pieces, or has exactly 1 opponent piece (blot).
 */
function isPointOpen(board, pointIndex, player) {
  const point = board.points[pointIndex];
  if (point.length === 0) return true;
  if (point[0] === player) return true;
  if (point.length === 1) return true; // blot
  return false;
}

/**
 * Get the opponent of a player.
 */
function opponent(player) {
  return player === WHITE ? BLACK : WHITE;
}

/**
 * Get the highest occupied point index in home board (for bearing off with higher die).
 */
function highestOccupiedInHome(board, player) {
  const home = getHomeBoardRange(player);
  if (player === WHITE) {
    // White home: indices 0-5, highest = index 5 (point 6)
    for (let i = home.end; i >= home.start; i--) {
      if (board.points[i].length > 0 && board.points[i][0] === player) {
        return i;
      }
    }
  } else {
    // Black home: indices 18-23, highest occupied = lowest index (furthest from bearing off)
    for (let i = home.start; i <= home.end; i++) {
      if (board.points[i].length > 0 && board.points[i][0] === player) {
        return i;
      }
    }
  }
  return -1;
}

/**
 * Convert a point index to the "point number" relative to a player.
 * For White: point number = index + 1 (so index 0 = point 1, closest to bear off)
 * For Black: point number = 24 - index (so index 23 = point 1, closest to bear off)
 */
function pointNumberForPlayer(index, player) {
  return player === WHITE ? index + 1 : TOTAL_POINTS - index;
}

/**
 * Convert a die value to the target index when bearing off or moving.
 * For bar entry:
 *   White enters at index (24 - dieValue) = 24 - die
 *   Black enters at index (dieValue - 1)
 * For regular moves:
 *   White: targetIndex = fromIndex - dieValue
 *   Black: targetIndex = fromIndex + dieValue
 */
function getTargetIndex(fromIndex, dieValue, player) {
  const direction = getMoveDirection(player);
  return fromIndex + direction * dieValue;
}

module.exports = {
  WHITE,
  BLACK,
  TOTAL_PIECES,
  TOTAL_POINTS,
  createInitialBoard,
  cloneBoard,
  serializeBoard,
  deserializeBoard,
  getMoveDirection,
  getHomeBoardRange,
  getBarEntryStart,
  countOnBoard,
  allInHomeBoard,
  isPointOpen,
  opponent,
  highestOccupiedInHome,
  pointNumberForPlayer,
  getTargetIndex,
};
