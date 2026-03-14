/**
 * ELO Rating & Scoring System
 *
 * K-factor: 32
 * Base: 1200 rating for new players
 * Result multipliers:
 *   - Normal win:     1x
 *   - Gammon:         2x (opponent has 0 pieces borne off)
 *   - Backgammon:     3x (opponent also has pieces in winner's home or on bar)
 *   - Resign:         1x (treated as normal for ELO)
 *   - Timeout:        1x
 *   - Disconnect:     1x
 */

const K_FACTOR = 32;
const BASE_RATING = 1200;
const MIN_RATING = 100;

const RESULT_MULTIPLIERS = {
  normal: 1,
  gammon: 2,
  backgammon: 3,
  resign: 1,
  timeout: 1,
  disconnect: 1,
};

/**
 * Calculate expected score using ELO formula.
 * E(A) = 1 / (1 + 10^((Rb - Ra) / 400))
 */
function expectedScore(ratingA, ratingB) {
  return 1 / (1 + Math.pow(10, (ratingB - ratingA) / 400));
}

/**
 * Calculate ELO rating changes for a game result.
 *
 * @param {number} winnerRating - Current rating of the winner
 * @param {number} loserRating - Current rating of the loser
 * @param {string} resultType - 'normal', 'gammon', 'backgammon', 'resign', 'timeout', 'disconnect'
 * @returns {{ winnerChange: number, loserChange: number, winnerNewRating: number, loserNewRating: number }}
 */
function calculateEloChange(winnerRating, loserRating, resultType) {
  const multiplier = RESULT_MULTIPLIERS[resultType] || 1;

  const expectedWin = expectedScore(winnerRating, loserRating);
  const expectedLose = expectedScore(loserRating, winnerRating);

  // Base change with K-factor
  const baseWinnerChange = K_FACTOR * (1 - expectedWin);
  const baseLoserChange = K_FACTOR * (0 - expectedLose);

  // Apply multiplier for gammon/backgammon
  const winnerChange = Math.round(baseWinnerChange * multiplier);
  const loserChange = Math.round(baseLoserChange * multiplier);

  const winnerNewRating = Math.max(MIN_RATING, winnerRating + winnerChange);
  const loserNewRating = Math.max(MIN_RATING, loserRating + loserChange);

  return {
    winnerChange,
    loserChange,
    winnerNewRating,
    loserNewRating,
  };
}

/**
 * Get the display label for a result type.
 */
function getResultLabel(resultType) {
  const labels = {
    normal: 'Normal Kazanç',
    gammon: 'Mars',
    backgammon: 'Üç Mars',
    resign: 'Teslim',
    timeout: 'Süre Aşımı',
    disconnect: 'Bağlantı Kopması',
  };
  return labels[resultType] || resultType;
}

/**
 * Get rating tier/rank name based on ELO.
 */
function getRatingTier(rating) {
  if (rating >= 2200) return { name: 'Grandmaster', tier: 7 };
  if (rating >= 2000) return { name: 'Master', tier: 6 };
  if (rating >= 1800) return { name: 'Expert', tier: 5 };
  if (rating >= 1600) return { name: 'Advanced', tier: 4 };
  if (rating >= 1400) return { name: 'Intermediate', tier: 3 };
  if (rating >= 1200) return { name: 'Beginner', tier: 2 };
  return { name: 'Novice', tier: 1 };
}

module.exports = {
  K_FACTOR,
  BASE_RATING,
  MIN_RATING,
  RESULT_MULTIPLIERS,
  expectedScore,
  calculateEloChange,
  getResultLabel,
  getRatingTier,
};
