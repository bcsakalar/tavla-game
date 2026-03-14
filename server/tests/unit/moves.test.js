const {
  createInitialBoard, cloneBoard, WHITE, BLACK, TOTAL_POINTS,
  isPointOpen, allInHomeBoard,
} = require('../../src/game/board');
const {
  BAR, OFF,
  getSingleMoves, applySingleMove,
  getValidMoveSequences, isMoveValid,
} = require('../../src/game/moves');

describe('Moves Module', () => {
  describe('getSingleMoves', () => {
    it('should return valid moves from initial position', () => {
      const board = createInitialBoard();
      const moves = getSingleMoves(board, WHITE, 6);

      // White has pieces at 23, 12, 7, 5
      // With die=6: 23→17, 12→6, 7→1
      expect(moves.length).toBeGreaterThan(0);
      const froms = moves.map((m) => m.from);
      expect(froms).toContain(23); // 23-6=17
      expect(froms).toContain(12); // 12-6=6
      expect(froms).toContain(7);  // 7-6=1
    });

    it('should force bar re-entry when piece is on bar', () => {
      const board = createInitialBoard();
      board.bar[WHITE] = 1;
      board.points[23].pop(); // Remove one from 23

      const moves = getSingleMoves(board, WHITE, 3);

      // Must enter from bar, can only go to point 24-3=21 (index 21)
      expect(moves).toHaveLength(1);
      expect(moves[0].from).toBe(BAR);
      expect(moves[0].to).toBe(21);
    });

    it('should return empty array when bar re-entry is blocked', () => {
      const board = createInitialBoard();
      board.bar[WHITE] = 1;
      board.points[23].pop();

      // Block all possible entry points for die values 1-6
      // White enters at 24-die, so block indices 23, 22, 21, 20, 19, 18
      for (let i = 18; i <= 23; i++) {
        board.points[i] = [BLACK, BLACK]; // Blocked by 2+ opponent pieces
      }

      for (let die = 1; die <= 6; die++) {
        const moves = getSingleMoves(board, WHITE, die);
        expect(moves).toHaveLength(0);
      }
    });

    it('should detect hits (blots)', () => {
      const board = createInitialBoard();
      // Place single Black piece at index 20
      board.points[20] = [BLACK];

      const moves = getSingleMoves(board, WHITE, 3);
      const hitMove = moves.find((m) => m.from === 23 && m.to === 20);

      expect(hitMove).toBeDefined();
      expect(hitMove.isHit).toBe(true);
    });

    it('should allow bearing off with exact die', () => {
      const board = createInitialBoard();
      // Clear board, put all White in home board
      for (let i = 0; i < TOTAL_POINTS; i++) board.points[i] = [];
      board.points[0] = Array(5).fill(WHITE);
      board.points[1] = Array(5).fill(WHITE);
      board.points[2] = Array(5).fill(WHITE);

      const moves = getSingleMoves(board, WHITE, 1);
      const bearOff = moves.find((m) => m.from === 0 && m.to === OFF);
      expect(bearOff).toBeDefined();
    });

    it('should allow bearing off with higher die from highest occupied', () => {
      const board = createInitialBoard();
      for (let i = 0; i < TOTAL_POINTS; i++) board.points[i] = [];
      // All pieces on point 2 (index 1)
      board.points[1] = Array(15).fill(WHITE);

      // Die 6 should allow bearing off from index 1 (point 2) since no higher points
      const moves = getSingleMoves(board, WHITE, 6);
      const bearOff = moves.find((m) => m.from === 1 && m.to === OFF);
      expect(bearOff).toBeDefined();
    });
  });

  describe('applySingleMove', () => {
    it('should move a piece from one point to another', () => {
      const board = createInitialBoard();
      const move = { from: 23, to: 20, dieValue: 3, isHit: false };
      const newBoard = applySingleMove(board, WHITE, move);

      expect(newBoard.points[23]).toHaveLength(1);
      expect(newBoard.points[20]).toContain(WHITE);
      // Original board should be unchanged
      expect(board.points[23]).toHaveLength(2);
    });

    it('should handle hits correctly', () => {
      const board = createInitialBoard();
      board.points[20] = [BLACK];

      const move = { from: 23, to: 20, dieValue: 3, isHit: true };
      const newBoard = applySingleMove(board, WHITE, move);

      expect(newBoard.points[20]).toEqual([WHITE]);
      expect(newBoard.bar[BLACK]).toBe(1);
    });

    it('should handle bar re-entry', () => {
      const board = createInitialBoard();
      board.bar[WHITE] = 1;
      board.points[23].pop();

      const move = { from: BAR, to: 21, dieValue: 3, isHit: false };
      const newBoard = applySingleMove(board, WHITE, move);

      expect(newBoard.bar[WHITE]).toBe(0);
      expect(newBoard.points[21]).toContain(WHITE);
    });

    it('should handle bearing off', () => {
      const board = createInitialBoard();
      for (let i = 0; i < TOTAL_POINTS; i++) board.points[i] = [];
      board.points[0] = Array(15).fill(WHITE);

      const move = { from: 0, to: OFF, dieValue: 1, isHit: false };
      const newBoard = applySingleMove(board, WHITE, move);

      expect(newBoard.borneOff[WHITE]).toBe(1);
      expect(newBoard.points[0]).toHaveLength(14);
    });
  });

  describe('getValidMoveSequences', () => {
    it('should return valid move sequences from initial position', () => {
      const board = createInitialBoard();
      const sequences = getValidMoveSequences(board, WHITE, [6, 1]);

      expect(sequences.length).toBeGreaterThan(0);
      // All sequences should use 2 dice (both must be used if possible)
      for (const seq of sequences) {
        expect(seq.moves).toHaveLength(2);
      }
    });

    it('should use maximum number of dice', () => {
      const board = createInitialBoard();
      const sequences = getValidMoveSequences(board, WHITE, [3, 4]);

      const maxMoves = Math.max(...sequences.map((s) => s.moves.length));
      // All sequences should use max dice count
      for (const seq of sequences) {
        expect(seq.moves).toHaveLength(maxMoves);
      }
    });

    it('should return 4-move sequences for doubles', () => {
      const board = createInitialBoard();
      const sequences = getValidMoveSequences(board, WHITE, [6, 6]);

      expect(sequences.length).toBeGreaterThan(0);
      // From initial position, White should be able to use all 4 sixes
      const maxMoves = Math.max(...sequences.map((s) => s.moves.length));
      expect(maxMoves).toBe(4);
    });

    it('should return empty moves when no moves possible', () => {
      const board = createInitialBoard();
      board.bar[WHITE] = 2;
      board.points[23].pop();
      board.points[23].pop();
      // Block all entry points for White
      for (let i = 18; i <= 23; i++) {
        board.points[i] = [BLACK, BLACK];
      }

      const sequences = getValidMoveSequences(board, WHITE, [3, 4]);
      // Should have one sequence with 0 moves (no legal moves)
      expect(sequences.length).toBe(1);
      expect(sequences[0].moves).toHaveLength(0);
    });

    it('should prefer higher die when only one can be used', () => {
      const board = createInitialBoard();
      // Setup: only one die can be used - force scenario where only die 5 works
      for (let i = 0; i < TOTAL_POINTS; i++) board.points[i] = [];
      board.points[10] = [WHITE]; // Single White piece at index 10

      // Block everything except index 5 (target for die=5: 10-5=5)
      for (let i = 0; i < TOTAL_POINTS; i++) {
        if (i === 10) continue;
        if (i === 5) continue;  // Allow die=5 destination
        board.points[i] = [BLACK, BLACK];
      }

      const sequences = getValidMoveSequences(board, WHITE, [3, 5]);
      // Only die 5 works (10→5), die 3 lands on 7 which is blocked
      expect(sequences.length).toBeGreaterThan(0);
      expect(sequences[0].moves).toHaveLength(1);
      expect(sequences[0].moves[0].dieValue).toBe(5);
    });
  });

  describe('isMoveValid', () => {
    it('should validate a legal move', () => {
      const board = createInitialBoard();
      const move = { from: 23, to: 17, dieValue: 6, isHit: false };

      expect(isMoveValid(board, WHITE, [6, 1], move, [])).toBe(true);
    });

    it('should reject an illegal move', () => {
      const board = createInitialBoard();
      // Try to move to a blocked point
      const move = { from: 23, to: 11, dieValue: 12, isHit: false };

      expect(isMoveValid(board, WHITE, [6, 6], move, [])).toBe(false);
    });
  });
});
