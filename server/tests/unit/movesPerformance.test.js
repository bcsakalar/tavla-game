const {
  createInitialBoard, cloneBoard, WHITE, BLACK, TOTAL_POINTS,
} = require('../../src/game/board');
const {
  BAR, OFF,
  getSingleMoves, applySingleMove, applyMoveInPlace, undoMoveInPlace,
  findAllMoveSequences, getValidMoveSequences, getMaxDiceUsable, isMoveValid,
} = require('../../src/game/moves');

describe('Moves Performance & Optimization', () => {
  describe('applyMoveInPlace / undoMoveInPlace', () => {
    it('should apply and undo a regular move correctly', () => {
      const board = createInitialBoard();
      const original = cloneBoard(board);
      const move = { from: 23, to: 20, dieValue: 3, isHit: false };

      const undo = applyMoveInPlace(board, WHITE, move);
      expect(board.points[23]).toHaveLength(1);
      expect(board.points[20]).toContain(WHITE);

      undoMoveInPlace(board, WHITE, move, undo);
      expect(board.points[23]).toHaveLength(2);
      expect(board.points[20]).toEqual(original.points[20]);
    });

    it('should apply and undo a hit move correctly', () => {
      const board = createInitialBoard();
      board.points[20] = [BLACK];
      const original = cloneBoard(board);
      const move = { from: 23, to: 20, dieValue: 3, isHit: true };

      const undo = applyMoveInPlace(board, WHITE, move);
      expect(board.points[20]).toEqual([WHITE]);
      expect(board.bar[BLACK]).toBe(1);

      undoMoveInPlace(board, WHITE, move, undo);
      expect(board.points[20]).toEqual([BLACK]);
      expect(board.bar[BLACK]).toBe(0);
      expect(board.points[23]).toEqual(original.points[23]);
    });

    it('should apply and undo a bar entry move correctly', () => {
      const board = createInitialBoard();
      board.bar[WHITE] = 1;
      board.points[23].pop();
      const move = { from: BAR, to: 21, dieValue: 3, isHit: false };

      const undo = applyMoveInPlace(board, WHITE, move);
      expect(board.bar[WHITE]).toBe(0);
      expect(board.points[21]).toContain(WHITE);

      undoMoveInPlace(board, WHITE, move, undo);
      expect(board.bar[WHITE]).toBe(1);
    });

    it('should apply and undo a bear off move correctly', () => {
      const board = createInitialBoard();
      for (let i = 0; i < TOTAL_POINTS; i++) board.points[i] = [];
      board.points[0] = Array(5).fill(WHITE);
      const move = { from: 0, to: OFF, dieValue: 1, isHit: false };

      const undo = applyMoveInPlace(board, WHITE, move);
      expect(board.borneOff[WHITE]).toBe(1);
      expect(board.points[0]).toHaveLength(4);

      undoMoveInPlace(board, WHITE, move, undo);
      expect(board.borneOff[WHITE]).toBe(0);
      expect(board.points[0]).toHaveLength(5);
    });
  });

  describe('getMaxDiceUsable', () => {
    it('should return 2 for normal dice from initial position', () => {
      const board = createInitialBoard();
      const max = getMaxDiceUsable(board, WHITE, [6, 1]);
      expect(max).toBe(2);
    });

    it('should return 4 for doubles from initial position', () => {
      const board = createInitialBoard();
      const max = getMaxDiceUsable(board, WHITE, [6, 6, 6, 6]);
      expect(max).toBe(4);
    });

    it('should return 0 when all moves are blocked', () => {
      const board = createInitialBoard();
      board.bar[WHITE] = 2;
      board.points[23].pop();
      board.points[23].pop();
      for (let i = 18; i <= 23; i++) {
        board.points[i] = [BLACK, BLACK];
      }

      const max = getMaxDiceUsable(board, WHITE, [3, 4]);
      expect(max).toBe(0);
    });

    it('should agree with getValidMoveSequences maxMoves', () => {
      const board = createInitialBoard();
      const dice = [5, 3];
      const sequences = getValidMoveSequences(board, WHITE, dice);
      const maxFromSequences = Math.max(...sequences.map((s) => s.moves.length));
      const { expandDice } = require('../../src/game/dice');
      const maxFromUsable = getMaxDiceUsable(board, WHITE, expandDice(dice));
      expect(maxFromUsable).toBe(maxFromSequences);
    });
  });

  describe('findAllMoveSequences correctness', () => {
    it('should return correct sequences for doubles', () => {
      const board = createInitialBoard();
      const { expandDice } = require('../../src/game/dice');
      const expanded = expandDice([6, 6]);
      const sequences = findAllMoveSequences(board, WHITE, expanded, []);

      expect(sequences.length).toBeGreaterThan(0);
      const maxMoves = Math.max(...sequences.map((s) => s.moves.length));
      expect(maxMoves).toBe(4);
    });

    it('should include board snapshots in results', () => {
      const board = createInitialBoard();
      const sequences = findAllMoveSequences(board, WHITE, [6, 1], []);

      for (const seq of sequences) {
        expect(seq.board).toBeDefined();
        expect(seq.board.points).toBeDefined();
        expect(seq.board.bar).toBeDefined();
        expect(seq.board.borneOff).toBeDefined();
      }
    });

    it('should not mutate the original board', () => {
      const board = createInitialBoard();
      const original = cloneBoard(board);
      const { expandDice } = require('../../src/game/dice');
      const expanded = expandDice([4, 4]);

      findAllMoveSequences(board, WHITE, expanded, []);

      // Board should be exactly as before
      for (let i = 0; i < TOTAL_POINTS; i++) {
        expect(board.points[i]).toEqual(original.points[i]);
      }
      expect(board.bar).toEqual(original.bar);
      expect(board.borneOff).toEqual(original.borneOff);
    });
  });

  describe('performance benchmarks', () => {
    it('should compute doubles within 50ms from initial position', () => {
      const board = createInitialBoard();
      const start = performance.now();
      const sequences = getValidMoveSequences(board, WHITE, [6, 6]);
      const elapsed = performance.now() - start;

      expect(sequences.length).toBeGreaterThan(0);
      expect(elapsed).toBeLessThan(50);
    });

    it('should compute 4-4 doubles within 50ms from initial position', () => {
      const board = createInitialBoard();
      const start = performance.now();
      const sequences = getValidMoveSequences(board, WHITE, [4, 4]);
      const elapsed = performance.now() - start;

      expect(sequences.length).toBeGreaterThan(0);
      expect(elapsed).toBeLessThan(50);
    });

    it('should compute isMoveValid within 50ms for doubles', () => {
      const board = createInitialBoard();
      const sequences = getValidMoveSequences(board, WHITE, [6, 6]);
      const firstMove = sequences[0].moves[0];

      const start = performance.now();
      const valid = isMoveValid(board, WHITE, [6, 6], firstMove, []);
      const elapsed = performance.now() - start;

      expect(valid).toBe(true);
      expect(elapsed).toBeLessThan(50);
    });

    it('should be faster than 100ms for worst-case bearing off doubles', () => {
      // All pieces in home board with doubles = many bearing off possibilities
      const board = createInitialBoard();
      for (let i = 0; i < TOTAL_POINTS; i++) board.points[i] = [];
      board.points[0] = Array(3).fill(WHITE);
      board.points[1] = Array(3).fill(WHITE);
      board.points[2] = Array(3).fill(WHITE);
      board.points[3] = Array(3).fill(WHITE);
      board.points[4] = Array(3).fill(WHITE);

      const start = performance.now();
      const sequences = getValidMoveSequences(board, WHITE, [3, 3]);
      const elapsed = performance.now() - start;

      expect(sequences.length).toBeGreaterThan(0);
      expect(elapsed).toBeLessThan(100);
    });
  });
});
