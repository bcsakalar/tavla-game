const express = require('express');
const router = express.Router();
const userService = require('../../services/userService');
const { authLimiter } = require('../../middleware/rateLimiter');

// POST /api/auth/register
router.post('/register', authLimiter, async (req, res, next) => {
  try {
    const { username, email, password } = req.body;
    const result = await userService.register(username, email, password);
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/login
router.post('/login', authLimiter, async (req, res, next) => {
  try {
    const { identifier, password } = req.body;
    const result = await userService.login(identifier, password);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/refresh
router.post('/refresh', authLimiter, async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token gerekli' });
    }
    const tokens = await userService.refreshToken(refreshToken);
    res.json(tokens);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
