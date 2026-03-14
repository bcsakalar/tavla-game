const db = require('../models/db');
const { serializeBoard } = require('../game/board');

/**
 * Create a game record in the database.
 */
async function createGameRecord(gameData) {
  const result = await db.query(
    `INSERT INTO games (white_player_id, black_player_id, status, board_state)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [gameData.whitePlayerId, gameData.blackPlayerId, 'playing', JSON.stringify(serializeBoard(gameData.board))],
  );
  return result.rows[0];
}

/**
 * Update game record with result.
 */
async function finishGameRecord(gameId, winnerId, resultType, boardState, eloChanges, totalMoves) {
  const result = await db.query(
    `UPDATE games SET
       status = 'finished',
       winner_id = $2,
       result_type = $3,
       board_state = $4,
       elo_change_white = $5,
       elo_change_black = $6,
       total_moves = $7,
       finished_at = NOW()
     WHERE id = $1
     RETURNING *`,
    [gameId, winnerId, resultType, JSON.stringify(boardState), eloChanges.white, eloChanges.black, totalMoves],
  );
  return result.rows[0];
}

/**
 * Save game move to history.
 */
async function saveGameMove(gameId, userId, moveNumber, diceValues, moves, boardAfter) {
  await db.query(
    `INSERT INTO game_moves (game_id, user_id, move_number, dice_values, moves, board_after)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [gameId, userId, moveNumber, diceValues, JSON.stringify(moves), JSON.stringify(boardAfter)],
  );
}

/**
 * Get game by ID with player info.
 */
async function getGameById(gameId) {
  const result = await db.query(
    `SELECT g.*,
            w.username AS white_username, w.avatar_url AS white_avatar, w.elo_rating AS white_elo,
            b.username AS black_username, b.avatar_url AS black_avatar, b.elo_rating AS black_elo
     FROM games g
     LEFT JOIN users w ON g.white_player_id = w.id
     LEFT JOIN users b ON g.black_player_id = b.id
     WHERE g.id = $1`,
    [gameId],
  );
  return result.rows[0] || null;
}

/**
 * Get user's game history.
 */
async function getUserGames(userId, limit = 20, offset = 0) {
  const result = await db.query(
    `SELECT g.id, g.status, g.result_type, g.winner_id,
            g.elo_change_white, g.elo_change_black, g.total_moves,
            g.created_at, g.finished_at,
            w.username AS white_username,
            b.username AS black_username
     FROM games g
     LEFT JOIN users w ON g.white_player_id = w.id
     LEFT JOIN users b ON g.black_player_id = b.id
     WHERE g.white_player_id = $1 OR g.black_player_id = $1
     ORDER BY g.created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset],
  );
  return result.rows;
}

/**
 * Get game moves history.
 */
async function getGameMoves(gameId) {
  const result = await db.query(
    `SELECT * FROM game_moves
     WHERE game_id = $1
     ORDER BY move_number ASC`,
    [gameId],
  );
  return result.rows;
}

/**
 * Save a chat message.
 */
async function saveChatMessage(gameId, userId, message, isSystem = false) {
  const result = await db.query(
    `INSERT INTO chat_messages (game_id, user_id, message, is_system)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [gameId, userId, message, isSystem],
  );
  return result.rows[0];
}

/**
 * Get chat messages for a game.
 */
async function getChatMessages(gameId) {
  const result = await db.query(
    `SELECT c.*, u.username
     FROM chat_messages c
     LEFT JOIN users u ON c.user_id = u.id
     WHERE c.game_id = $1
     ORDER BY c.created_at ASC`,
    [gameId],
  );
  return result.rows;
}

/**
 * Update daily statistics.
 */
async function updateDailyStats(field) {
  const today = new Date().toISOString().split('T')[0];
  await db.query(
    `INSERT INTO daily_stats (date, ${field})
     VALUES ($1, 1)
     ON CONFLICT (date) DO UPDATE SET ${field} = daily_stats.${field} + 1`,
    [today],
  );
}

module.exports = {
  createGameRecord,
  finishGameRecord,
  saveGameMove,
  getGameById,
  getUserGames,
  getGameMoves,
  saveChatMessage,
  getChatMessages,
  updateDailyStats,
};
