const { validateMoveData } = require('../../src/socket/handlers/game');

describe('validateMoveData', () => {
  it('should accept valid move from point to point', () => {
    const result = validateMoveData({ from: 5, to: 3, dieValue: 2 });
    expect(result).toEqual({ from: 5, to: 3, dieValue: 2 });
  });

  it('should accept move from bar', () => {
    const result = validateMoveData({ from: 'bar', to: 20 });
    expect(result).toEqual({ from: 'bar', to: 20, dieValue: undefined });
  });

  it('should accept move to off', () => {
    const result = validateMoveData({ from: 0, to: 'off', dieValue: 1 });
    expect(result).toEqual({ from: 0, to: 'off', dieValue: 1 });
  });

  it('should accept move without dieValue', () => {
    const result = validateMoveData({ from: 12, to: 8 });
    expect(result).toEqual({ from: 12, to: 8, dieValue: undefined });
  });

  it('should reject null input', () => {
    expect(validateMoveData(null)).toBeNull();
  });

  it('should reject undefined input', () => {
    expect(validateMoveData(undefined)).toBeNull();
  });

  it('should reject non-object input', () => {
    expect(validateMoveData('move')).toBeNull();
    expect(validateMoveData(42)).toBeNull();
  });

  it('should reject invalid from values', () => {
    expect(validateMoveData({ from: -1, to: 5 })).toBeNull();
    expect(validateMoveData({ from: 24, to: 5 })).toBeNull();
    expect(validateMoveData({ from: 'off', to: 5 })).toBeNull();
    expect(validateMoveData({ from: 1.5, to: 5 })).toBeNull();
  });

  it('should reject invalid to values', () => {
    expect(validateMoveData({ from: 5, to: -1 })).toBeNull();
    expect(validateMoveData({ from: 5, to: 24 })).toBeNull();
    expect(validateMoveData({ from: 5, to: 'bar' })).toBeNull();
    expect(validateMoveData({ from: 5, to: 2.5 })).toBeNull();
  });

  it('should reject invalid dieValue', () => {
    expect(validateMoveData({ from: 5, to: 3, dieValue: 0 })).toBeNull();
    expect(validateMoveData({ from: 5, to: 3, dieValue: 7 })).toBeNull();
    expect(validateMoveData({ from: 5, to: 3, dieValue: 1.5 })).toBeNull();
    expect(validateMoveData({ from: 5, to: 3, dieValue: 'two' })).toBeNull();
  });

  it('should accept dieValue as null (treats as undefined)', () => {
    const result = validateMoveData({ from: 5, to: 3, dieValue: null });
    expect(result).toEqual({ from: 5, to: 3, dieValue: undefined });
  });

  it('should accept boundary values for from and to', () => {
    expect(validateMoveData({ from: 0, to: 0 })).toEqual({ from: 0, to: 0, dieValue: undefined });
    expect(validateMoveData({ from: 23, to: 23 })).toEqual({ from: 23, to: 23, dieValue: undefined });
  });

  it('should accept boundary dieValues 1 and 6', () => {
    expect(validateMoveData({ from: 5, to: 3, dieValue: 1 })).toEqual({ from: 5, to: 3, dieValue: 1 });
    expect(validateMoveData({ from: 5, to: 3, dieValue: 6 })).toEqual({ from: 5, to: 3, dieValue: 6 });
  });
});
