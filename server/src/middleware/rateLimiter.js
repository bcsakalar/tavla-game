const rateLimit = require('express-rate-limit');

/**
 * Rate limiter for API routes.
 */
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Çok fazla istek, lütfen daha sonra tekrar deneyin' },
});

/**
 * Rate limiter for auth routes (login/register).
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Çok fazla giriş denemesi, lütfen daha sonra tekrar deneyin' },
});

module.exports = { apiLimiter, authLimiter };
