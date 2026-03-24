const AppError = require('../../src/utils/AppError');

describe('AppError', () => {
  it('should create an error with message and statusCode', () => {
    const err = new AppError('Not found', 404);
    expect(err).toBeInstanceOf(Error);
    expect(err).toBeInstanceOf(AppError);
    expect(err.message).toBe('Not found');
    expect(err.statusCode).toBe(404);
    expect(err.type).toBeUndefined();
  });

  it('should include optional type', () => {
    const err = new AppError('Bad request', 400, 'VALIDATION');
    expect(err.type).toBe('VALIDATION');
  });

  it('should have a stack trace', () => {
    const err = new AppError('test', 500);
    expect(err.stack).toBeDefined();
    expect(err.stack).toContain('test');
  });

  it('should default statusCode to undefined when not provided', () => {
    const err = new AppError('msg');
    expect(err.message).toBe('msg');
    expect(err.statusCode).toBeUndefined();
  });
});
