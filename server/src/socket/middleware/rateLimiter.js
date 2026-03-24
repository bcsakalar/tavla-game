/**
 * Socket event rate limiter middleware.
 * Per-socket throttle using in-memory token bucket.
 */

const logger = require('../../utils/logger');

// Rate limits per event category: { max, windowMs }
const RATE_LIMITS = {
  move: { max: 30, windowMs: 10000 },
  chat: { max: 10, windowMs: 10000 },
  emoji: { max: 20, windowMs: 10000 },
};

// Map event names to categories
const EVENT_CATEGORY = {
  'game:move': 'move',
  'bot:move': 'move',
  'game:rollDice': 'move',
  'bot:rollDice': 'move',
  'game:endTurn': 'move',
  'bot:endTurn': 'move',
  'game:undoMove': 'move',
  'bot:undoMove': 'move',
  'game:chat': 'chat',
  'game:emoji': 'emoji',
};

/**
 * Create rate limit state for a socket.
 * Returns a function that checks if an event should be allowed.
 */
function createSocketRateLimiter() {
  // buckets: Map<category, { count, resetAt }>
  const buckets = new Map();

  return function isAllowed(eventName) {
    const category = EVENT_CATEGORY[eventName];
    if (!category) return true; // Untracked events are always allowed

    const limit = RATE_LIMITS[category];
    const now = Date.now();

    let bucket = buckets.get(category);
    if (!bucket || now >= bucket.resetAt) {
      bucket = { count: 0, resetAt: now + limit.windowMs };
      buckets.set(category, bucket);
    }

    bucket.count++;
    return bucket.count <= limit.max;
  };
}

/**
 * Socket.IO middleware that attaches rate limiter to each socket.
 * Call socket.rateLimitCheck(eventName) before processing events.
 */
function socketRateLimitMiddleware(socket, next) {
  socket.rateLimitCheck = createSocketRateLimiter();
  next();
}

module.exports = { socketRateLimitMiddleware, createSocketRateLimiter, EVENT_CATEGORY };
