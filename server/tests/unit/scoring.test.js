const {
  K_FACTOR, BASE_RATING, MIN_RATING,
  expectedScore, calculateEloChange,
  getResultLabel, getRatingTier,
} = require('../../src/game/scoring');

describe('Scoring Module', () => {
  describe('expectedScore', () => {
    it('should return 0.5 for equal ratings', () => {
      expect(expectedScore(1200, 1200)).toBeCloseTo(0.5);
    });

    it('should return > 0.5 for higher-rated player', () => {
      expect(expectedScore(1600, 1200)).toBeGreaterThan(0.5);
    });

    it('should return < 0.5 for lower-rated player', () => {
      expect(expectedScore(1200, 1600)).toBeLessThan(0.5);
    });

    it('should have complementary probabilities', () => {
      const a = expectedScore(1400, 1200);
      const b = expectedScore(1200, 1400);
      expect(a + b).toBeCloseTo(1.0);
    });
  });

  describe('calculateEloChange', () => {
    it('should give equal changes for equal ratings (normal win)', () => {
      const result = calculateEloChange(1200, 1200, 'normal');

      expect(result.winnerChange).toBe(16); // K/2 rounded
      expect(result.loserChange).toBe(-16);
      expect(result.winnerNewRating).toBe(1216);
      expect(result.loserNewRating).toBe(1184);
    });

    it('should give smaller change when higher-rated wins', () => {
      const result = calculateEloChange(1600, 1200, 'normal');

      // Higher-rated was expected to win → small reward
      expect(result.winnerChange).toBeLessThan(16);
      expect(result.winnerChange).toBeGreaterThan(0);
    });

    it('should give larger change when lower-rated wins', () => {
      const result = calculateEloChange(1200, 1600, 'normal');

      // Lower-rated upset → big reward
      expect(result.winnerChange).toBeGreaterThan(16);
    });

    it('should apply 2x multiplier for gammon', () => {
      const normal = calculateEloChange(1200, 1200, 'normal');
      const gammon = calculateEloChange(1200, 1200, 'gammon');

      expect(gammon.winnerChange).toBe(normal.winnerChange * 2);
    });

    it('should apply 3x multiplier for backgammon', () => {
      const normal = calculateEloChange(1200, 1200, 'normal');
      const backgammon = calculateEloChange(1200, 1200, 'backgammon');

      expect(backgammon.winnerChange).toBe(normal.winnerChange * 3);
    });

    it('should apply 1x multiplier for resign/timeout/disconnect', () => {
      const normal = calculateEloChange(1200, 1200, 'normal');

      for (const type of ['resign', 'timeout', 'disconnect']) {
        const result = calculateEloChange(1200, 1200, type);
        expect(result.winnerChange).toBe(normal.winnerChange);
      }
    });

    it('should not drop below MIN_RATING', () => {
      const result = calculateEloChange(1200, MIN_RATING, 'backgammon');

      expect(result.loserNewRating).toBe(MIN_RATING);
    });
  });

  describe('getResultLabel', () => {
    it('should return Turkish labels', () => {
      expect(getResultLabel('normal')).toBe('Normal Kazanç');
      expect(getResultLabel('gammon')).toBe('Mars');
      expect(getResultLabel('backgammon')).toBe('Üç Mars');
      expect(getResultLabel('resign')).toBe('Teslim');
      expect(getResultLabel('timeout')).toBe('Süre Aşımı');
      expect(getResultLabel('disconnect')).toBe('Bağlantı Kopması');
    });
  });

  describe('getRatingTier', () => {
    it('should map ratings to correct tiers', () => {
      expect(getRatingTier(2300).name).toBe('Grandmaster');
      expect(getRatingTier(2000).name).toBe('Master');
      expect(getRatingTier(1800).name).toBe('Expert');
      expect(getRatingTier(1600).name).toBe('Advanced');
      expect(getRatingTier(1400).name).toBe('Intermediate');
      expect(getRatingTier(1200).name).toBe('Beginner');
      expect(getRatingTier(1100).name).toBe('Novice');
    });
  });
});
