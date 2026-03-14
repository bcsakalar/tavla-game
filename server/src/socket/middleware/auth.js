const jwt = require('jsonwebtoken');
const config = require('../../config');

/**
 * Socket.IO authentication middleware.
 * Validates JWT from handshake auth.
 */
function socketAuth(socket, next) {
  const token = socket.handshake.auth.token;

  if (!token) {
    return next(new Error('Yetkilendirme gerekli'));
  }

  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    socket.user = decoded;
    next();
  } catch (err) {
    next(new Error('Geçersiz token'));
  }
}

module.exports = { socketAuth };
