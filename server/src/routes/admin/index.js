const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const db = require('../../models/db');
const { adminAuth } = require('../../middleware/auth');
const { adminLoginLimiter } = require('../../middleware/rateLimiter');
const { csrfToken, csrfProtection } = require('../../middleware/csrf');
const logger = require('../../utils/logger');

// Attach CSRF token to all admin requests
router.use(csrfToken);

// GET /admin/login
router.get('/login', (req, res) => {
  if (req.session.admin) return res.redirect('/admin');
  res.render('admin/login', { error: null });
});

// POST /admin/login
router.post('/login', adminLoginLimiter, csrfProtection, async (req, res) => {
  try {
    const { username, password } = req.body;
    const result = await db.query(
      "SELECT * FROM users WHERE username = $1 AND role = 'admin'",
      [username],
    );

    if (result.rows.length === 0) {
      return res.render('admin/login', { error: 'Hatalı kullanıcı adı veya şifre' });
    }

    const admin = result.rows[0];
    const valid = await bcrypt.compare(password, admin.password_hash);

    if (!valid) {
      return res.render('admin/login', { error: 'Hatalı kullanıcı adı veya şifre' });
    }

    req.session.admin = { id: admin.id, username: admin.username };
    res.redirect('/admin');
  } catch (err) {
    logger.error('Admin', 'Login error', err);
    res.render('admin/login', { error: 'Sunucu hatası' });
  }
});

// GET /admin/logout
router.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/admin/login');
});

// === Protected routes below ===
router.use(adminAuth);

// GET /admin - Dashboard
router.get('/', async (req, res) => {
  try {
    const [users, games, todayStats, onlineCount] = await Promise.all([
      db.query('SELECT COUNT(*) AS count FROM users'),
      db.query('SELECT COUNT(*) AS count FROM games'),
      db.query(
        "SELECT * FROM daily_stats WHERE date = CURRENT_DATE",
      ),
      db.query("SELECT COUNT(*) AS count FROM users WHERE is_online = true"),
    ]);

    const stats = {
      totalUsers: parseInt(users.rows[0].count),
      totalGames: parseInt(games.rows[0].count),
      todayGames: todayStats.rows[0]?.total_games || 0,
      todayNewUsers: todayStats.rows[0]?.total_new_users || 0,
      onlineUsers: parseInt(onlineCount.rows[0].count),
    };

    res.render('admin/dashboard', { admin: req.session.admin, stats, page: 'dashboard' });
  } catch (err) {
    logger.error('Admin', 'Dashboard error', err);
    res.render('admin/dashboard', { admin: req.session.admin, stats: {}, page: 'dashboard' });
  }
});

// GET /admin/users
router.get('/users', async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = 20;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';

    let query = `SELECT id, username, email, elo_rating,
                        total_wins, total_losses, total_draws,
                        is_online, is_banned, role, created_at
                 FROM users`;
    const params = [];

    if (search) {
      query += ' WHERE username ILIKE $1 OR email ILIKE $1';
      params.push(`%${search}%`);
    }

    query += ' ORDER BY created_at DESC LIMIT $' + (params.length + 1) + ' OFFSET $' + (params.length + 2);
    params.push(limit, offset);

    const result = await db.query(query, params);
    const countResult = await db.query(
      'SELECT COUNT(*) FROM users' + (search ? ' WHERE username ILIKE $1 OR email ILIKE $1' : ''),
      search ? [`%${search}%`] : [],
    );

    const total = parseInt(countResult.rows[0].count);

    res.render('admin/users', {
      admin: req.session.admin,
      users: result.rows,
      page: 'users',
      currentPage: page,
      totalPages: Math.ceil(total / limit),
      search,
    });
  } catch (err) {
    logger.error('Admin', 'Users error', err);
    res.render('admin/users', { admin: req.session.admin, users: [], page: 'users', currentPage: 1, totalPages: 1, search: '' });
  }
});

// POST /admin/users/:id/ban
router.post('/users/:id/ban', csrfProtection, async (req, res) => {
  try {
    const userId = parseInt(req.params.id, 10);
    await db.query('UPDATE users SET is_banned = NOT is_banned WHERE id = $1', [userId]);
    res.redirect('/admin/users');
  } catch (err) {
    logger.error('Admin', 'Ban error', err);
    res.redirect('/admin/users');
  }
});

// GET /admin/games
router.get('/games', async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = 20;
    const offset = (page - 1) * limit;

    const result = await db.query(
      `SELECT g.id, g.status, g.result_type, g.total_moves,
              g.created_at, g.finished_at,
              w.username AS white_username,
              b.username AS black_username,
              winner.username AS winner_username
       FROM games g
       LEFT JOIN users w ON g.white_player_id = w.id
       LEFT JOIN users b ON g.black_player_id = b.id
       LEFT JOIN users winner ON g.winner_id = winner.id
       ORDER BY g.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset],
    );

    const countResult = await db.query('SELECT COUNT(*) FROM games');
    const total = parseInt(countResult.rows[0].count);

    res.render('admin/games', {
      admin: req.session.admin,
      games: result.rows,
      page: 'games',
      currentPage: page,
      totalPages: Math.ceil(total / limit),
    });
  } catch (err) {
    logger.error('Admin', 'Games error', err);
    res.render('admin/games', { admin: req.session.admin, games: [], page: 'games', currentPage: 1, totalPages: 1 });
  }
});

// GET /admin/reports
router.get('/reports', async (req, res) => {
  try {
    const result = await db.query(
      `SELECT r.*, 
              reporter.username AS reporter_username,
              reported.username AS reported_username
       FROM reports r
       LEFT JOIN users reporter ON r.reporter_id = reporter.id
       LEFT JOIN users reported ON r.reported_id = reported.id
       ORDER BY r.created_at DESC
       LIMIT 50`,
    );

    res.render('admin/reports', {
      admin: req.session.admin,
      reports: result.rows,
      page: 'reports',
    });
  } catch (err) {
    logger.error('Admin', 'Reports error', err);
    res.render('admin/reports', { admin: req.session.admin, reports: [], page: 'reports' });
  }
});

// POST /admin/reports/:id/resolve
router.post('/reports/:id/resolve', csrfProtection, async (req, res) => {
  try {
    const reportId = parseInt(req.params.id, 10);
    const { admin_note } = req.body;
    await db.query(
      "UPDATE reports SET status = 'resolved', admin_note = $2 WHERE id = $1",
      [reportId, admin_note || ''],
    );
    res.redirect('/admin/reports');
  } catch (err) {
    logger.error('Admin', 'Resolve error', err);
    res.redirect('/admin/reports');
  }
});

module.exports = router;
