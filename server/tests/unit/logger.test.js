const logger = require('../../src/utils/logger');

describe('Logger', () => {
  let consoleSpy;

  beforeEach(() => {
    consoleSpy = jest.spyOn(console, 'log').mockImplementation();
    jest.spyOn(console, 'warn').mockImplementation();
    jest.spyOn(console, 'error').mockImplementation();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('should have info, warn, error, debug methods', () => {
    expect(typeof logger.info).toBe('function');
    expect(typeof logger.warn).toBe('function');
    expect(typeof logger.error).toBe('function');
    expect(typeof logger.debug).toBe('function');
  });

  it('should log info messages with tag', () => {
    logger.info('TestTag', 'hello world');
    expect(consoleSpy).toHaveBeenCalled();
    const output = consoleSpy.mock.calls[0][0];
    expect(output).toContain('INFO');
    expect(output).toContain('TestTag');
    expect(output).toContain('hello world');
  });

  it('should log warn messages', () => {
    logger.warn('Warn', 'something happened');
    expect(console.warn).toHaveBeenCalled();
  });

  it('should log error messages with stack trace', () => {
    const err = new Error('test error');
    logger.error('Err', 'failed', err);
    expect(console.error).toHaveBeenCalled();
  });
});
