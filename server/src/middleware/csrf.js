/**
 * Simple CSRF protection middleware for admin panel.
 * Uses a random token stored in the session and validated on POST requests.
 */

const crypto = require('crypto');

/**
 * Ensure a CSRF token exists in the session.
 * Makes it available as res.locals.csrfToken for EJS templates.
 */
function csrfToken(req, res, next) {
  if (!req.session.csrfToken) {
    req.session.csrfToken = crypto.randomBytes(32).toString('hex');
  }
  res.locals.csrfToken = req.session.csrfToken;
  next();
}

/**
 * Validate CSRF token on POST/PUT/PATCH/DELETE requests.
 * Token can be in body._csrf or header x-csrf-token.
 */
function csrfProtection(req, res, next) {
  if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
    return next();
  }

  const token = req.body._csrf || req.headers['x-csrf-token'];
  if (!token || token !== req.session.csrfToken) {
    return res.status(403).render('admin/login', { error: 'CSRF doğrulama hatası. Lütfen tekrar deneyin.' });
  }
  next();
}

module.exports = { csrfToken, csrfProtection };
