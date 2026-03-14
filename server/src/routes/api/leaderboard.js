const express = require('express');
const router = express.Router();
const userService = require('../../services/userService');

// GET /api/leaderboard
router.get('/', async (req, res, next) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
    const offset = parseInt(req.query.offset, 10) || 0;
    const leaderboard = await userService.getLeaderboard(limit, offset);
    res.json(leaderboard);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
