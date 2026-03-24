/**
 * Application error class with HTTP status code support.
 */
class AppError extends Error {
  constructor(message, statusCode, type) {
    super(message);
    this.statusCode = statusCode;
    if (type) this.type = type;
  }
}

module.exports = AppError;
