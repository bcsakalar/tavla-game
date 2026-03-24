const { socketRateLimitMiddleware, createSocketRateLimiter } = require('../../src/socket/middleware/rateLimiter');

describe('Socket Rate Limiter', () => {
  describe('createSocketRateLimiter', () => {
    it('should allow events under the limit', () => {
      const isAllowed = createSocketRateLimiter();
      // 30 moves allowed in 10s window
      for (let i = 0; i < 30; i++) {
        expect(isAllowed('game:move')).toBe(true);
      }
    });

    it('should reject events over the limit', () => {
      const isAllowed = createSocketRateLimiter();
      for (let i = 0; i < 30; i++) {
        isAllowed('game:move');
      }
      expect(isAllowed('game:move')).toBe(false);
    });

    it('should track different categories separately', () => {
      const isAllowed = createSocketRateLimiter();
      // Exhaust move category
      for (let i = 0; i < 30; i++) {
        isAllowed('game:move');
      }
      expect(isAllowed('game:move')).toBe(false);
      // Chat category should still work
      expect(isAllowed('game:chat')).toBe(true);
    });

    it('should always allow untracked events', () => {
      const isAllowed = createSocketRateLimiter();
      expect(isAllowed('game:reconnect')).toBe(true);
      expect(isAllowed('game:resign')).toBe(true);
    });

    it('should enforce chat limit of 10', () => {
      const isAllowed = createSocketRateLimiter();
      for (let i = 0; i < 10; i++) {
        expect(isAllowed('game:chat')).toBe(true);
      }
      expect(isAllowed('game:chat')).toBe(false);
    });

    it('should enforce emoji limit of 20', () => {
      const isAllowed = createSocketRateLimiter();
      for (let i = 0; i < 20; i++) {
        expect(isAllowed('game:emoji')).toBe(true);
      }
      expect(isAllowed('game:emoji')).toBe(false);
    });
  });

  describe('socketRateLimitMiddleware', () => {
    it('should attach rateLimitCheck to socket and call next', () => {
      const socket = {};
      const next = jest.fn();
      socketRateLimitMiddleware(socket, next);
      expect(typeof socket.rateLimitCheck).toBe('function');
      expect(next).toHaveBeenCalled();
    });
  });
});
