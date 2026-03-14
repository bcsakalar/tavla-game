const jwt = require('jsonwebtoken');
const config = require('../config');

/**
 * JWT authentication middleware for API routes.
 * Extracts token from Authorization header (Bearer <token>).
 */
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Yetkilendirme başlığı gerekli' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token süresi dolmuş' });
    }
    return res.status(401).json({ error: 'Geçersiz token' });
  }
}

/**
 * Optional auth — populates req.user if token exists, but doesn't block.
 */
function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  const token = authHeader.split(' ')[1];
  try {
    req.user = jwt.verify(token, config.jwt.secret);
  } catch {
    // Ignore invalid tokens for optional auth
  }
  next();
}

/**
 * Admin-only middleware for admin panel.
 */
function adminAuth(req, res, next) {
  if (!req.session || !req.session.admin) {
    return res.redirect('/admin/login');
  }
  next();
}

/**
 * Generate access + refresh token pair.
 */
function generateTokens(user) {
  const payload = {
    id: user.id,
    username: user.username,
    role: user.role,
  };

  const accessToken = jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn,
  });

  const refreshToken = jwt.sign(
    { id: user.id },
    config.jwt.refreshSecret,
    { expiresIn: config.jwt.refreshExpiresIn },
  );

  return { accessToken, refreshToken };
}

module.exports = { authMiddleware, optionalAuth, adminAuth, generateTokens };
