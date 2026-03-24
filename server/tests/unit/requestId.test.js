const requestId = require('../../src/middleware/requestId');

describe('requestId middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {};
    res = {
      setHeader: jest.fn(),
    };
    next = jest.fn();
  });

  it('should set req.id as UUID', () => {
    requestId(req, res, next);
    expect(req.id).toBeDefined();
    // UUID v4 format
    expect(req.id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
  });

  it('should set X-Request-ID response header', () => {
    requestId(req, res, next);
    expect(res.setHeader).toHaveBeenCalledWith('X-Request-ID', req.id);
  });

  it('should call next', () => {
    requestId(req, res, next);
    expect(next).toHaveBeenCalled();
  });

  it('should generate unique IDs per request', () => {
    const req2 = {};
    const res2 = { setHeader: jest.fn() };
    requestId(req, res, next);
    requestId(req2, res2, next);
    expect(req.id).not.toBe(req2.id);
  });
});
