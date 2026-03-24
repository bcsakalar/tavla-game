const { ALLOWED_EMOJIS, RESULT_TYPES, AVATAR_URL_MAX_LENGTH, CHAT_MESSAGE_MAX_LENGTH } = require('../../src/config/constants');

describe('Constants', () => {
  it('should define allowed emojis as non-empty array', () => {
    expect(Array.isArray(ALLOWED_EMOJIS)).toBe(true);
    expect(ALLOWED_EMOJIS.length).toBeGreaterThan(0);
  });

  it('should define result types including standard types', () => {
    expect(RESULT_TYPES).toContain('normal');
    expect(RESULT_TYPES).toContain('gammon');
    expect(RESULT_TYPES).toContain('backgammon');
    expect(RESULT_TYPES).toContain('resign');
    expect(RESULT_TYPES).toContain('timeout');
    expect(RESULT_TYPES).toContain('disconnect');
  });

  it('should define numeric limits', () => {
    expect(typeof AVATAR_URL_MAX_LENGTH).toBe('number');
    expect(AVATAR_URL_MAX_LENGTH).toBeGreaterThan(0);
    expect(typeof CHAT_MESSAGE_MAX_LENGTH).toBe('number');
    expect(CHAT_MESSAGE_MAX_LENGTH).toBeGreaterThan(0);
  });
});
