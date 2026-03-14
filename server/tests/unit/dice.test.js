const { rollDice, expandDice, rollInitialDice } = require('../../src/game/dice');

describe('Dice Module', () => {
  describe('rollDice', () => {
    it('should return an array of 2 numbers', () => {
      const result = rollDice();
      expect(result).toHaveLength(2);
      expect(typeof result[0]).toBe('number');
      expect(typeof result[1]).toBe('number');
    });

    it('should return values between 1 and 6', () => {
      // Roll many times to ensure range
      for (let i = 0; i < 100; i++) {
        const [d1, d2] = rollDice();
        expect(d1).toBeGreaterThanOrEqual(1);
        expect(d1).toBeLessThanOrEqual(6);
        expect(d2).toBeGreaterThanOrEqual(1);
        expect(d2).toBeLessThanOrEqual(6);
      }
    });
  });

  describe('expandDice', () => {
    it('should return 2 values for non-doubles', () => {
      expect(expandDice([3, 5])).toEqual([3, 5]);
      expect(expandDice([1, 6])).toEqual([1, 6]);
    });

    it('should return 4 values for doubles', () => {
      expect(expandDice([4, 4])).toEqual([4, 4, 4, 4]);
      expect(expandDice([1, 1])).toEqual([1, 1, 1, 1]);
      expect(expandDice([6, 6])).toEqual([6, 6, 6, 6]);
    });
  });

  describe('rollInitialDice', () => {
    it('should return different dice values', () => {
      for (let i = 0; i < 50; i++) {
        const { dice } = rollInitialDice();
        expect(dice[0]).not.toBe(dice[1]);
      }
    });

    it('should return White or Black as first player', () => {
      for (let i = 0; i < 50; i++) {
        const { firstPlayer } = rollInitialDice();
        expect(['W', 'B']).toContain(firstPlayer);
      }
    });

    it('should assign first player based on higher die', () => {
      for (let i = 0; i < 50; i++) {
        const { dice, firstPlayer } = rollInitialDice();
        if (dice[0] > dice[1]) {
          expect(firstPlayer).toBe('W');
        } else {
          expect(firstPlayer).toBe('B');
        }
      }
    });
  });
});
