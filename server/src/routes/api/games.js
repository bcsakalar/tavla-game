const express = require('express');
const router = express.Router();
const gameService = require('../../services/gameService');
const { authMiddleware } = require('../../middleware/auth');

// GET /api/games/:id - Get game details
router.get('/:id', async (req, res, next) => {
  try {
    const gameId = parseInt(req.params.id, 10);
    if (isNaN(gameId)) {
      return res.status(400).json({ error: 'Geçersiz oyun ID' });
    }
    const game = await gameService.getGameById(gameId);
    if (!game) {
      return res.status(404).json({ error: 'Oyun bulunamadı' });
    }
    res.json(game);
  } catch (err) {
    next(err);
  }
});

// GET /api/games/:id/moves - Get game move history
router.get('/:id/moves', async (req, res, next) => {
  try {
    const gameId = parseInt(req.params.id, 10);
    if (isNaN(gameId)) {
      return res.status(400).json({ error: 'Geçersiz oyun ID' });
    }
    const moves = await gameService.getGameMoves(gameId);
    res.json(moves);
  } catch (err) {
    next(err);
  }
});

// GET /api/games/:id/chat - Get game chat messages
router.get('/:id/chat', authMiddleware, async (req, res, next) => {
  try {
    const gameId = parseInt(req.params.id, 10);
    if (isNaN(gameId)) {
      return res.status(400).json({ error: 'Geçersiz oyun ID' });
    }
    const messages = await gameService.getChatMessages(gameId);
    res.json(messages);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
