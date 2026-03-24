/**
 * Game state store — Redis-backed with in-memory fallback.
 *
 * Persists active game states so they survive server restarts.
 * Keys: game:{gameId} → JSON game state
 * Sets: activeGames → set of active game IDs
 *       playerGame:{userId} → gameId
 */

const redis = require('../config/redis');
const logger = require('../utils/logger');

const GAME_TTL = 4 * 60 * 60; // 4 hours

/**
 * Save a game state to Redis.
 */
async function saveGame(gameId, gameState) {
  if (!redis) return;
  try {
    const data = JSON.stringify(gameState);
    await redis.set(`game:${gameId}`, data, 'EX', GAME_TTL);
    await redis.sadd('activeGames', String(gameId));
  } catch (err) {
    logger.warn('StateStore', `Failed to save game ${gameId}: ${err.message}`);
  }
}

/**
 * Load a game state from Redis.
 */
async function loadGame(gameId) {
  if (!redis) return null;
  try {
    const data = await redis.get(`game:${gameId}`);
    return data ? JSON.parse(data) : null;
  } catch (err) {
    logger.warn('StateStore', `Failed to load game ${gameId}: ${err.message}`);
    return null;
  }
}

/**
 * Delete a game state from Redis.
 */
async function deleteGame(gameId) {
  if (!redis) return;
  try {
    await redis.del(`game:${gameId}`);
    await redis.srem('activeGames', String(gameId));
  } catch (err) {
    logger.warn('StateStore', `Failed to delete game ${gameId}: ${err.message}`);
  }
}

/**
 * Map a player to their active game.
 */
async function setPlayerGame(userId, gameId) {
  if (!redis) return;
  try {
    await redis.set(`playerGame:${userId}`, String(gameId), 'EX', GAME_TTL);
  } catch (err) {
    logger.warn('StateStore', `Failed to set player game: ${err.message}`);
  }
}

/**
 * Get a player's active game ID.
 */
async function getPlayerGame(userId) {
  if (!redis) return null;
  try {
    return await redis.get(`playerGame:${userId}`);
  } catch (err) {
    logger.warn('StateStore', `Failed to get player game: ${err.message}`);
    return null;
  }
}

/**
 * Remove a player's game mapping.
 */
async function deletePlayerGame(userId) {
  if (!redis) return;
  try {
    await redis.del(`playerGame:${userId}`);
  } catch (err) {
    logger.warn('StateStore', `Failed to delete player game: ${err.message}`);
  }
}

/**
 * Load all active games from Redis (for recovery on boot).
 * Returns Map<gameId, gameState>.
 */
async function loadAllGames() {
  if (!redis) return new Map();
  try {
    const gameIds = await redis.smembers('activeGames');
    const games = new Map();
    for (const id of gameIds) {
      const state = await loadGame(id);
      if (state) {
        games.set(id, state);
      } else {
        // Stale entry — clean up
        await redis.srem('activeGames', id);
      }
    }
    logger.info('StateStore', `Recovered ${games.size} active games from Redis`);
    return games;
  } catch (err) {
    logger.warn('StateStore', `Failed to load all games: ${err.message}`);
    return new Map();
  }
}

/**
 * Save all active games to Redis (for graceful shutdown).
 */
async function saveAllGames(activeGames) {
  if (!redis) return;
  let saved = 0;
  for (const [gameId, gameState] of activeGames) {
    await saveGame(gameId, gameState);
    saved++;
  }
  logger.info('StateStore', `Saved ${saved} active games to Redis`);
}

module.exports = {
  saveGame,
  loadGame,
  deleteGame,
  setPlayerGame,
  getPlayerGame,
  deletePlayerGame,
  loadAllGames,
  saveAllGames,
};
