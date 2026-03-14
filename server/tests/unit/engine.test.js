const {
  createInitialBoard, WHITE, BLACK, TOTAL_POINTS, opponent,
} = require('../../src/game/board');
const {
  GameState, TurnPhase,
  createGame, startGame, rollTurnDice, makeMove,
  getResultType, resignGame, timeoutGame, disconnectGame,
  getGameSnapshot, getPlayerColor,
} = require('../../src/game/engine');

describe('Engine Module', () => {
  describe('createGame', () => {
    it('should create a game in waiting state', () => {
      const game = createGame('user1', 'user2');

      expect(game.state).toBe(GameState.WAITING);
      expect(game.whitePlayerId).toBe('user1');
      expect(game.blackPlayerId).toBe('user2');
      expect(game.currentTurn).toBeNull();
      expect(game.winner).toBeNull();
      expect(game.moveHistory).toEqual([]);
    });
  });

  describe('startGame', () => {
    it('should start the game with initial dice roll', () => {
      const game = createGame('user1', 'user2');
      const result = startGame(game);

      expect(result.success).toBe(true);
      expect(game.state).toBe(GameState.PLAYING);
      expect([WHITE, BLACK]).toContain(game.currentTurn);
      expect(result.dice).toHaveLength(2);
      expect(result.dice[0]).not.toBe(result.dice[1]);
      expect(game.startedAt).toBeInstanceOf(Date);
    });

    it('should fail to start an already started game', () => {
      const game = createGame('user1', 'user2');
      startGame(game);
      const result = startGame(game);

      expect(result.success).toBe(false);
      expect(result.error).toContain('not in waiting state');
    });
  });

  describe('makeMove', () => {
    it('should allow a valid move', () => {
      const game = createGame('user1', 'user2');
      const startResult = startGame(game);

      // Get the current player's legal moves to test with
      const { getValidMoveSequences } = require('../../src/game/moves');
      const sequences = getValidMoveSequences(game.board, game.currentTurn, game.dice);

      if (sequences.length > 0 && sequences[0].moves.length > 0) {
        const firstMove = sequences[0].moves[0];
        const result = makeMove(game, game.currentTurn, firstMove);
        expect(result.success).toBe(true);
      }
    });

    it('should reject move when not your turn', () => {
      const game = createGame('user1', 'user2');
      startGame(game);

      const wrongPlayer = opponent(game.currentTurn);
      const move = { from: 0, to: 1, dieValue: 1, isHit: false };
      const result = makeMove(game, wrongPlayer, move);

      expect(result.success).toBe(false);
      expect(result.error).toContain('Not your turn');
    });
  });

  describe('getResultType', () => {
    it('should return normal when loser has borne off pieces', () => {
      const game = createGame('user1', 'user2');
      game.board = createInitialBoard();
      game.board.borneOff[BLACK] = 3;

      const result = getResultType(game, WHITE);
      expect(result).toBe('normal');
    });

    it('should return gammon when loser has 0 pieces borne off', () => {
      const game = createGame('user1', 'user2');
      game.board = createInitialBoard();
      game.board.borneOff[BLACK] = 0;
      // Ensure no Black pieces in White's home or on bar
      for (let i = 0; i < TOTAL_POINTS; i++) {
        if (game.board.points[i].length > 0 && game.board.points[i][0] === BLACK) {
          // Move Black pieces outside White's home (0-5)
          if (i <= 5) {
            game.board.points[i] = [];
            game.board.points[10] = [...(game.board.points[10] || []), BLACK];
          }
        }
      }

      const result = getResultType(game, WHITE);
      expect(result).toBe('gammon');
    });

    it('should return backgammon when loser has pieces on bar', () => {
      const game = createGame('user1', 'user2');
      game.board = createInitialBoard();
      game.board.borneOff[BLACK] = 0;
      game.board.bar[BLACK] = 1;

      const result = getResultType(game, WHITE);
      expect(result).toBe('backgammon');
    });

    it('should return backgammon when loser has pieces in winners home', () => {
      const game = createGame('user1', 'user2');
      game.board = createInitialBoard();
      game.board.borneOff[BLACK] = 0;
      // Black has pieces at index 0 which is in White's home (0-5)
      // Index 0 already has Black pieces in initial setup #✓

      const result = getResultType(game, WHITE);
      expect(result).toBe('backgammon');
    });
  });

  describe('resignGame', () => {
    it('should end game with opponent as winner', () => {
      const game = createGame('user1', 'user2');
      startGame(game);

      const result = resignGame(game, game.currentTurn);

      expect(result.success).toBe(true);
      expect(result.gameOver).toBe(true);
      expect(result.winner).toBe(opponent(game.currentTurn));
      expect(result.resultType).toBe('resign');
      expect(game.state).toBe(GameState.FINISHED);
    });
  });

  describe('timeoutGame', () => {
    it('should end game with opponent of timed-out player as winner', () => {
      const game = createGame('user1', 'user2');
      startGame(game);

      const currentPlayer = game.currentTurn;
      const result = timeoutGame(game);

      expect(result.success).toBe(true);
      expect(result.winner).toBe(opponent(currentPlayer));
      expect(result.resultType).toBe('timeout');
    });
  });

  describe('disconnectGame', () => {
    it('should end game with connected player as winner', () => {
      const game = createGame('user1', 'user2');
      startGame(game);

      const result = disconnectGame(game, WHITE);

      expect(result.success).toBe(true);
      expect(result.winner).toBe(BLACK);
      expect(result.resultType).toBe('disconnect');
    });
  });

  describe('getGameSnapshot', () => {
    it('should return a serializable snapshot', () => {
      const game = createGame('user1', 'user2');
      startGame(game);

      const snapshot = getGameSnapshot(game);

      expect(snapshot.state).toBe(GameState.PLAYING);
      expect(snapshot.board).toBeDefined();
      expect(snapshot.currentTurn).toBeDefined();
      expect(snapshot.whitePlayerId).toBe('user1');
      expect(snapshot.blackPlayerId).toBe('user2');
      expect(snapshot.borneOff).toEqual({ W: 0, B: 0 });
    });
  });

  describe('getPlayerColor', () => {
    it('should return correct color for player IDs', () => {
      const game = createGame('user1', 'user2');

      expect(getPlayerColor(game, 'user1')).toBe(WHITE);
      expect(getPlayerColor(game, 'user2')).toBe(BLACK);
      expect(getPlayerColor(game, 'user3')).toBeNull();
    });
  });
});
