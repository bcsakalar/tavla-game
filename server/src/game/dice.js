/**
 * Cryptographically secure dice rolling for Tavla.
 * Uses crypto.randomInt to ensure fairness (no Math.random).
 */

const { randomInt } = require('crypto');

/**
 * Roll two dice. Returns [die1, die2] where each is 1-6.
 */
function rollDice() {
  return [randomInt(1, 7), randomInt(1, 7)];
}

/**
 * Expand dice into individual moves.
 * Normal roll: [3, 5] → [3, 5]
 * Doubles: [4, 4] → [4, 4, 4, 4]
 */
function expandDice(dice) {
  if (dice[0] === dice[1]) {
    return [dice[0], dice[0], dice[0], dice[0]];
  }
  return [...dice];
}

/**
 * Roll initial dice for determining who goes first.
 * Re-rolls if both dice are the same.
 * Returns { dice: [die1, die2], firstPlayer: 'W' | 'B' }
 */
function rollInitialDice() {
  let die1, die2;
  do {
    die1 = randomInt(1, 7);
    die2 = randomInt(1, 7);
  } while (die1 === die2);

  return {
    dice: [die1, die2],
    firstPlayer: die1 > die2 ? 'W' : 'B',
  };
}

module.exports = {
  rollDice,
  expandDice,
  rollInitialDice,
};
