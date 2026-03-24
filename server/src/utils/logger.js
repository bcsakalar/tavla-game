/**
 * Structured logger utility.
 * Format: [LEVEL] [TAG] message
 */

const levels = { debug: 0, info: 1, warn: 2, error: 3 };

const currentLevel = levels[process.env.LOG_LEVEL] || levels.info;

function formatMessage(level, tag, message) {
  const ts = new Date().toISOString();
  return `[${level.toUpperCase()}] [${tag}] ${ts} ${message}`;
}

const logger = {
  debug(tag, message) {
    if (currentLevel <= levels.debug) {
      console.log(formatMessage('debug', tag, message));
    }
  },

  info(tag, message) {
    if (currentLevel <= levels.info) {
      console.log(formatMessage('info', tag, message));
    }
  },

  warn(tag, message) {
    if (currentLevel <= levels.warn) {
      console.warn(formatMessage('warn', tag, message));
    }
  },

  error(tag, message, err) {
    if (currentLevel <= levels.error) {
      const base = formatMessage('error', tag, message);
      if (err && err.stack) {
        console.error(`${base}\n${err.stack}`);
      } else {
        console.error(base);
      }
    }
  },
};

module.exports = logger;
