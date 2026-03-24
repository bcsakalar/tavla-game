/**
 * Express error handling middleware.
 */

const logger = require('../utils/logger');

function notFound(req, res, _next) {
  res.status(404).json({ error: 'Sayfa bulunamadı' });
}

function errorHandler(err, req, res, _next) {
  logger.error('HTTP', `${req.method} ${req.originalUrl} [reqId=${req.id || '-'}]`, err);

  if (err.type === 'validation') {
    return res.status(400).json({ error: err.message });
  }

  const statusCode = err.statusCode || 500;
  const message = statusCode === 500 ? 'Sunucu hatası' : err.message;

  res.status(statusCode).json({ error: message });
}

module.exports = { notFound, errorHandler };
