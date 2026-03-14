/**
 * Game module barrel export.
 */

const board = require('./board');
const dice = require('./dice');
const moves = require('./moves');
const engine = require('./engine');
const scoring = require('./scoring');

module.exports = {
  ...board,
  ...dice,
  ...moves,
  ...engine,
  ...scoring,
};
