const express = require('express');
const router = express.Router();
const userService = require('../../services/userService');
const gameService = require('../../services/gameService');
const { authMiddleware } = require('../../middleware/auth');

// GET /api/users/me - Get current user profile
router.get('/me', authMiddleware, async (req, res, next) => {
  try {
    const user = await userService.getProfile(req.user.id);
    res.json(user);
  } catch (err) {
    next(err);
  }
});

// PATCH /api/users/me - Update current user profile
router.patch('/me', authMiddleware, async (req, res, next) => {
  try {
    const updated = await userService.updateProfile(req.user.id, req.body);
    res.json(updated);
  } catch (err) {
    next(err);
  }
});

// GET /api/users/:id - Get user profile by ID
router.get('/:id', async (req, res, next) => {
  try {
    const userId = parseInt(req.params.id, 10);
    if (isNaN(userId)) {
      return res.status(400).json({ error: 'Geçersiz kullanıcı ID' });
    }
    const user = await userService.getProfile(userId);
    res.json(user);
  } catch (err) {
    next(err);
  }
});

// GET /api/users/:id/games - Get user's game history
router.get('/:id/games', async (req, res, next) => {
  try {
    const userId = parseInt(req.params.id, 10);
    if (isNaN(userId)) {
      return res.status(400).json({ error: 'Geçersiz kullanıcı ID' });
    }
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);
    const offset = parseInt(req.query.offset, 10) || 0;
    const games = await gameService.getUserGames(userId, limit, offset);
    res.json(games);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
