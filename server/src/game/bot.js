/**
 * Bot AI for practice mode.
 *
 * Difficulty levels:
 *   - easy: Random valid move selection
 *   - medium: Basic strategy (prefer hits, avoid blots)
 *   - hard: Advanced positional play
 */

const { getValidMoveSequences } = require('./moves');
const { randomInt } = require('crypto');

/**
 * Choose a move sequence for the bot based on difficulty.
 * @param {object} board - Current board state
 * @param {string} player - Bot's color ('W' or 'B')
 * @param {number[]} dice - Dice values
 * @param {string} difficulty - 'easy', 'medium', or 'hard'
 * @returns {object[]} Array of moves to execute
 */
function chooseMoves(board, player, dice, difficulty = 'easy') {
  const sequences = getValidMoveSequences(board, player, dice);

  if (sequences.length === 0 || sequences.every((s) => s.moves.length === 0)) {
    return [];
  }

  // Filter to only sequences with moves
  const validSequences = sequences.filter((s) => s.moves.length > 0);
  if (validSequences.length === 0) return [];

  switch (difficulty) {
    case 'medium':
      return chooseMedium(validSequences, player);
    case 'hard':
      return chooseHard(validSequences, player);
    default:
      return chooseEasy(validSequences);
  }
}

/**
 * Easy: Pick a random valid move sequence.
 */
function chooseEasy(sequences) {
  const idx = randomInt(0, sequences.length);
  return sequences[idx].moves;
}

/**
 * Medium: Prefer sequences that hit opponent pieces.
 * Secondary: prefer sequences that use more dice.
 */
function chooseMedium(sequences, player) {
  // Score each sequence
  const scored = sequences.map((seq) => {
    let score = seq.moves.length * 10; // Prefer using more dice
    for (const move of seq.moves) {
      if (move.isHit) score += 50; // Strongly prefer hitting
      if (move.to === 'off') score += 30; // Prefer bearing off
    }
    return { seq, score };
  });

  scored.sort((a, b) => b.score - a.score);

  // Pick from top 3 with some randomness
  const topN = Math.min(3, scored.length);
  const idx = randomInt(0, topN);
  return scored[idx].seq.moves;
}

/**
 * Hard: Positional strategy - block points, avoid blots, build primes.
 */
function chooseHard(sequences, player) {
  const scored = sequences.map((seq) => {
    let score = seq.moves.length * 10;
    const board = seq.board;

    for (const move of seq.moves) {
      if (move.isHit) score += 40;
      if (move.to === 'off') score += 35;
    }

    // Evaluate resulting board position
    for (let i = 0; i < 24; i++) {
      const point = board.points[i];
      if (point.length > 0 && point[0] === player) {
        if (point.length === 1) {
          score -= 15; // Penalize blots (exposed pieces)
        } else if (point.length >= 2) {
          score += 5; // Reward made points (2+ pieces)
        }
        if (point.length >= 3) {
          score += 3; // Slight bonus for building towers
        }
      }
    }

    // Penalize pieces on bar
    score -= board.bar[player] * 20;

    return { seq, score };
  });

  scored.sort((a, b) => b.score - a.score);

  // Pick best
  return scored[0].seq.moves;
}

module.exports = { chooseMoves };
