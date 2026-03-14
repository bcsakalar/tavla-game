const {
  createInitialBoard, cloneBoard, serializeBoard, deserializeBoard,
  WHITE, BLACK, TOTAL_PIECES, TOTAL_POINTS,
  getMoveDirection, getHomeBoardRange, getBarEntryStart,
  countOnBoard, allInHomeBoard, isPointOpen, opponent,
  highestOccupiedInHome, pointNumberForPlayer, getTargetIndex,
} = require('../../src/game/board');

describe('Board Module', () => {
  describe('createInitialBoard', () => {
    it('should create a board with correct initial setup', () => {
      const board = createInitialBoard();

      // Should have 24 points
      expect(board.points).toHaveLength(TOTAL_POINTS);

      // White pieces: indices 23(2), 12(5), 7(3), 5(5)
      expect(board.points[23]).toEqual([WHITE, WHITE]);
      expect(board.points[12]).toEqual([WHITE, WHITE, WHITE, WHITE, WHITE]);
      expect(board.points[7]).toEqual([WHITE, WHITE, WHITE]);
      expect(board.points[5]).toEqual([WHITE, WHITE, WHITE, WHITE, WHITE]);

      // Black pieces: indices 0(2), 11(5), 16(3), 18(5)
      expect(board.points[0]).toEqual([BLACK, BLACK]);
      expect(board.points[11]).toEqual([BLACK, BLACK, BLACK, BLACK, BLACK]);
      expect(board.points[16]).toEqual([BLACK, BLACK, BLACK]);
      expect(board.points[18]).toEqual([BLACK, BLACK, BLACK, BLACK, BLACK]);

      // Bar and borne off should start at 0
      expect(board.bar).toEqual({ W: 0, B: 0 });
      expect(board.borneOff).toEqual({ W: 0, B: 0 });
    });

    it('should have exactly 15 pieces per player', () => {
      const board = createInitialBoard();
      expect(countOnBoard(board, WHITE)).toBe(TOTAL_PIECES);
      expect(countOnBoard(board, BLACK)).toBe(TOTAL_PIECES);
    });
  });

  describe('cloneBoard', () => {
    it('should create a deep copy', () => {
      const board = createInitialBoard();
      const clone = cloneBoard(board);

      // Should be equal but not the same reference
      expect(clone).toEqual(board);
      expect(clone).not.toBe(board);
      expect(clone.points).not.toBe(board.points);
      expect(clone.points[0]).not.toBe(board.points[0]);

      // Modifying clone shouldn't affect original
      clone.points[0].push(WHITE);
      expect(board.points[0]).toHaveLength(2);
    });
  });

  describe('serializeBoard / deserializeBoard', () => {
    it('should round-trip correctly', () => {
      const board = createInitialBoard();
      const serialized = serializeBoard(board);
      const deserialized = deserializeBoard(serialized);

      expect(deserialized).toEqual(board);
    });

    it('should produce compact format', () => {
      const board = createInitialBoard();
      const serialized = serializeBoard(board);

      expect(serialized.bar).toEqual({ W: 0, B: 0 });
      expect(serialized.borneOff).toEqual({ W: 0, B: 0 });
      expect(serialized.points).toHaveLength(TOTAL_POINTS);

      // Non-empty points have count and player
      expect(serialized.points[23]).toEqual({ count: 2, player: WHITE });
      expect(serialized.points[0]).toEqual({ count: 2, player: BLACK });

      // Empty points have count 0 and player null
      expect(serialized.points[1]).toEqual({ count: 0, player: null });
    });
  });

  describe('getMoveDirection', () => {
    it('should return -1 for White (high to low)', () => {
      expect(getMoveDirection(WHITE)).toBe(-1);
    });

    it('should return 1 for Black (low to high)', () => {
      expect(getMoveDirection(BLACK)).toBe(1);
    });
  });

  describe('getHomeBoardRange', () => {
    it('should return 0-5 for White', () => {
      expect(getHomeBoardRange(WHITE)).toEqual({ start: 0, end: 5 });
    });

    it('should return 18-23 for Black', () => {
      expect(getHomeBoardRange(BLACK)).toEqual({ start: 18, end: 23 });
    });
  });

  describe('getBarEntryStart', () => {
    it('should return 23 for White', () => {
      expect(getBarEntryStart(WHITE)).toBe(23);
    });

    it('should return 0 for Black', () => {
      expect(getBarEntryStart(BLACK)).toBe(0);
    });
  });

  describe('allInHomeBoard', () => {
    it('should return false at game start', () => {
      const board = createInitialBoard();
      expect(allInHomeBoard(board, WHITE)).toBe(false);
      expect(allInHomeBoard(board, BLACK)).toBe(false);
    });

    it('should return true when all pieces are in home board', () => {
      const board = createInitialBoard();
      // Clear all points
      for (let i = 0; i < TOTAL_POINTS; i++) board.points[i] = [];
      // Put all White pieces in home board (0-5)
      board.points[0] = Array(5).fill(WHITE);
      board.points[1] = Array(5).fill(WHITE);
      board.points[2] = Array(5).fill(WHITE);

      expect(allInHomeBoard(board, WHITE)).toBe(true);
    });

    it('should return false when piece is on bar', () => {
      const board = createInitialBoard();
      for (let i = 0; i < TOTAL_POINTS; i++) board.points[i] = [];
      board.points[0] = Array(14).fill(WHITE);
      board.bar[WHITE] = 1;

      expect(allInHomeBoard(board, WHITE)).toBe(false);
    });
  });

  describe('isPointOpen', () => {
    it('should return true for empty point', () => {
      const board = createInitialBoard();
      expect(isPointOpen(board, 1, WHITE)).toBe(true);
    });

    it('should return true for own pieces', () => {
      const board = createInitialBoard();
      expect(isPointOpen(board, 23, WHITE)).toBe(true);
    });

    it('should return true for single opponent (blot)', () => {
      const board = createInitialBoard();
      board.points[10] = [BLACK];
      expect(isPointOpen(board, 10, WHITE)).toBe(true);
    });

    it('should return false for 2+ opponent pieces', () => {
      const board = createInitialBoard();
      expect(isPointOpen(board, 0, WHITE)).toBe(false); // 2 Black pieces
    });
  });

  describe('opponent', () => {
    it('should return BLACK for WHITE', () => {
      expect(opponent(WHITE)).toBe(BLACK);
    });

    it('should return WHITE for BLACK', () => {
      expect(opponent(BLACK)).toBe(WHITE);
    });
  });

  describe('pointNumberForPlayer', () => {
    it('should return correct point numbers for White', () => {
      expect(pointNumberForPlayer(0, WHITE)).toBe(1);   // Closest to home
      expect(pointNumberForPlayer(5, WHITE)).toBe(6);
      expect(pointNumberForPlayer(23, WHITE)).toBe(24);  // Farthest from home
    });

    it('should return correct point numbers for Black', () => {
      expect(pointNumberForPlayer(23, BLACK)).toBe(1);   // Closest to home
      expect(pointNumberForPlayer(18, BLACK)).toBe(6);
      expect(pointNumberForPlayer(0, BLACK)).toBe(24);   // Farthest from home
    });
  });

  describe('getTargetIndex', () => {
    it('should calculate correct target for White moving down', () => {
      expect(getTargetIndex(23, 6, WHITE)).toBe(17);
    });

    it('should calculate correct target for Black moving up', () => {
      expect(getTargetIndex(0, 6, BLACK)).toBe(6);
    });
  });
});
