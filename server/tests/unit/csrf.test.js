const { csrfToken, csrfProtection } = require('../../src/middleware/csrf');

describe('CSRF Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      session: {},
      method: 'GET',
      body: {},
      headers: {},
    };
    res = {
      locals: {},
      status: jest.fn().mockReturnThis(),
      render: jest.fn(),
    };
    next = jest.fn();
  });

  describe('csrfToken', () => {
    it('should generate a token and set it in session and locals', () => {
      csrfToken(req, res, next);
      expect(req.session.csrfToken).toBeDefined();
      expect(typeof req.session.csrfToken).toBe('string');
      expect(req.session.csrfToken.length).toBe(64); // 32 bytes hex
      expect(res.locals.csrfToken).toBe(req.session.csrfToken);
      expect(next).toHaveBeenCalled();
    });

    it('should reuse existing token', () => {
      req.session.csrfToken = 'existing-token';
      csrfToken(req, res, next);
      expect(req.session.csrfToken).toBe('existing-token');
      expect(res.locals.csrfToken).toBe('existing-token');
    });
  });

  describe('csrfProtection', () => {
    it('should skip validation for GET requests', () => {
      req.method = 'GET';
      csrfProtection(req, res, next);
      expect(next).toHaveBeenCalled();
    });

    it('should skip validation for HEAD requests', () => {
      req.method = 'HEAD';
      csrfProtection(req, res, next);
      expect(next).toHaveBeenCalled();
    });

    it('should reject POST without token', () => {
      req.method = 'POST';
      req.session.csrfToken = 'valid-token';
      csrfProtection(req, res, next);
      expect(res.status).toHaveBeenCalledWith(403);
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject POST with wrong token', () => {
      req.method = 'POST';
      req.session.csrfToken = 'valid-token';
      req.body._csrf = 'wrong-token';
      csrfProtection(req, res, next);
      expect(res.status).toHaveBeenCalledWith(403);
      expect(next).not.toHaveBeenCalled();
    });

    it('should accept POST with correct body token', () => {
      req.method = 'POST';
      req.session.csrfToken = 'valid-token';
      req.body._csrf = 'valid-token';
      csrfProtection(req, res, next);
      expect(next).toHaveBeenCalled();
    });

    it('should accept POST with correct header token', () => {
      req.method = 'POST';
      req.session.csrfToken = 'valid-token';
      req.headers['x-csrf-token'] = 'valid-token';
      csrfProtection(req, res, next);
      expect(next).toHaveBeenCalled();
    });
  });
});
