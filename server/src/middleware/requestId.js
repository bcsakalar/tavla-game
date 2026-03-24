const crypto = require('crypto');

/**
 * Middleware that assigns a unique request ID to each request.
 * Sets req.id and X-Request-ID response header.
 */
function requestId(req, res, next) {
  req.id = crypto.randomUUID();
  res.setHeader('X-Request-ID', req.id);
  next();
}

module.exports = requestId;
