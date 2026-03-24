const bcrypt = require('bcrypt');
const db = require('../models/db');
const { generateTokens } = require('../middleware/auth');
const jwt = require('jsonwebtoken');
const config = require('../config');
const AppError = require('../utils/AppError');
const { AVATAR_URL_MAX_LENGTH } = require('../config/constants');

const SALT_ROUNDS = 12;

/**
 * Register a new user.
 */
async function register(username, email, password) {
  // Validate input lengths
  if (!username || username.length < 3 || username.length > 20) {
    throw new AppError('Kullanıcı adı 3-20 karakter olmalı', 400);
  }
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new AppError('Geçerli bir email adresi girin', 400);
  }
  if (!password || password.length < 8) {
    throw new AppError('Şifre en az 8 karakter olmalı', 400);
  }
  if (!/^[a-zA-Z0-9_]+$/.test(username)) {
    throw new AppError('Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir', 400);
  }

  // Check existing
  const existing = await db.query(
    'SELECT id FROM users WHERE username = $1 OR email = $2',
    [username, email.toLowerCase()],
  );
  if (existing.rows.length > 0) {
    throw new AppError('Bu kullanıcı adı veya email zaten kullanılıyor', 409);
  }

  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

  const result = await db.query(
    `INSERT INTO users (username, email, password_hash)
     VALUES ($1, $2, $3)
     RETURNING id, username, email, elo_rating, role, created_at`,
    [username, email.toLowerCase(), passwordHash],
  );

  const user = result.rows[0];
  const tokens = generateTokens(user);

  return { user, ...tokens };
}

/**
 * Login with username/email and password.
 */
async function login(identifier, password) {
  const result = await db.query(
    'SELECT * FROM users WHERE username = $1 OR email = $2',
    [identifier, identifier.toLowerCase()],
  );

  if (result.rows.length === 0) {
    throw Object.assign(new Error('Kullanıcı adı veya şifre hatalı'), { statusCode: 401 });
  }

  const user = result.rows[0];

  if (user.is_banned) {
    throw new AppError('Hesabınız engellenmiş', 403);
  }

  const validPassword = await bcrypt.compare(password, user.password_hash);
  if (!validPassword) {
    throw new AppError('Kullanıcı adı veya şifre hatalı', 401);
  }

  // Update last login
  await db.query(
    'UPDATE users SET is_online = true, updated_at = NOW() WHERE id = $1',
    [user.id],
  );

  const tokens = generateTokens(user);
  const { password_hash, ...safeUser } = user;

  return { user: safeUser, ...tokens };
}

/**
 * Refresh access token using refresh token.
 */
async function refreshToken(token) {
  try {
    const decoded = jwt.verify(token, config.jwt.refreshSecret);
    const result = await db.query(
      'SELECT id, username, email, role FROM users WHERE id = $1',
      [decoded.id],
    );

    if (result.rows.length === 0) {
      throw new AppError('Kullanıcı bulunamadı', 404);
    }

    const user = result.rows[0];
    const tokens = generateTokens(user);

    return tokens;
  } catch (err) {
    if (err.statusCode) throw err;
    throw new AppError('Geçersiz refresh token', 401);
  }
}

/**
 * Get user profile by ID.
 */
async function getProfile(userId) {
  const result = await db.query(
    `SELECT id, username, email, avatar_url, elo_rating,
            total_wins, total_losses, total_draws,
            total_gammons, total_backgammons, role, created_at
     FROM users WHERE id = $1`,
    [userId],
  );

  if (result.rows.length === 0) {
    throw new AppError('Kullanıcı bulunamadı', 404);
  }

  return result.rows[0];
}

/**
 * Update user profile.
 */
async function updateProfile(userId, updates) {
  const allowed = ['avatar_url'];
  const setClauses = [];
  const values = [];
  let paramIndex = 1;

  // Validate avatar_url
  if (updates.avatar_url !== undefined && updates.avatar_url !== null) {
    const url = String(updates.avatar_url);
    if (url.length > AVATAR_URL_MAX_LENGTH) {
      throw new AppError(`Avatar URL en fazla ${AVATAR_URL_MAX_LENGTH} karakter olabilir`, 400);
    }
    if (url.length > 0) {
      try {
        const parsed = new URL(url);
        if (!['http:', 'https:'].includes(parsed.protocol)) {
          throw new AppError('Avatar URL yalnızca http veya https olabilir', 400);
        }
      } catch (err) {
        if (err instanceof AppError) throw err;
        throw new AppError('Geçersiz avatar URL formatı', 400);
      }
    }
  }

  for (const key of allowed) {
    if (updates[key] !== undefined) {
      setClauses.push(`${key} = $${paramIndex}`);
      values.push(updates[key]);
      paramIndex++;
    }
  }

  if (setClauses.length === 0) {
    throw new AppError('Güncellenecek alan belirtilmedi', 400);
  }

  values.push(userId);
  const result = await db.query(
    `UPDATE users SET ${setClauses.join(', ')}, updated_at = NOW()
     WHERE id = $${paramIndex}
     RETURNING id, username, email, avatar_url, elo_rating`,
    values,
  );

  return result.rows[0];
}

/**
 * Get leaderboard (top players by ELO).
 */
async function getLeaderboard(limit = 50, offset = 0) {
  const result = await db.query(
    `SELECT id, username, avatar_url, elo_rating,
            total_wins, total_losses, total_draws,
            total_gammons, total_backgammons
     FROM users
     WHERE role = 'player' AND (total_wins + total_losses + total_draws) > 0
     ORDER BY elo_rating DESC
     LIMIT $1 OFFSET $2`,
    [limit, offset],
  );

  return result.rows;
}

/**
 * Update user stats after game ends.
 */
async function updateGameStats(userId, isWinner, resultType) {
  const isGammon = resultType === 'gammon';
  const isBackgammon = resultType === 'backgammon';

  if (isWinner) {
    await db.query(
      `UPDATE users SET
         total_wins = total_wins + 1,
         total_gammons = total_gammons + $2,
         total_backgammons = total_backgammons + $3,
         updated_at = NOW()
       WHERE id = $1`,
      [userId, isGammon ? 1 : 0, isBackgammon ? 1 : 0],
    );
  } else {
    await db.query(
      `UPDATE users SET
         total_losses = total_losses + 1,
         updated_at = NOW()
       WHERE id = $1`,
      [userId],
    );
  }
}

/**
 * Update user ELO rating.
 */
async function updateEloRating(userId, newRating) {
  await db.query(
    'UPDATE users SET elo_rating = $2, updated_at = NOW() WHERE id = $1',
    [userId, newRating],
  );
}

module.exports = {
  register,
  login,
  refreshToken,
  getProfile,
  updateProfile,
  getLeaderboard,
  updateGameStats,
  updateEloRating,
};
