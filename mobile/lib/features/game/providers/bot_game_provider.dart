import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/haptic/haptic_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/game_state.dart';
import 'game_provider.dart';

final botGameProvider =
    StateNotifierProvider.autoDispose<BotGameNotifier, GamePlayState>((ref) {
  final socket = ref.read(socketServiceProvider);
  return BotGameNotifier(socket);
});

class BotGameNotifier extends StateNotifier<GamePlayState> {
  final SocketService _socket;
  final AudioManager _audio = AudioManager();

  BotGameNotifier(this._socket) : super(const GamePlayState(isBotGame: true)) {
    _setupListeners();
  }

  void startBotGame(String difficulty, int myUserId) {
    // Remove previous listener to avoid duplicates on restart
    _socket.off('bot:gameStarted');

    _socket.on('bot:gameStarted', (data) {
      if (!mounted) return;
      final snapshot =
          GameSnapshot.fromJson(Map<String, dynamic>.from(data['snapshot']));
      final myColor =
          snapshot.whitePlayerId == myUserId.toString() ? 'W' : 'B';

      state = state.copyWith(
        phase: GamePhase.playing,
        snapshot: snapshot,
        myColor: myColor,
        isBotGame: true,
      );
    });

    _socket.emit('bot:startGame', {'difficulty': difficulty});
  }

  void _setupListeners() {
    _socket.on('bot:diceRolled', (data) {
      if (!mounted) return;
      final snapshot =
          GameSnapshot.fromJson(Map<String, dynamic>.from(data['snapshot']));
      _audio.play(AudioManager.diceRoll);
      HapticHelper.mediumImpact();

      state = state.copyWith(
        snapshot: snapshot,
        phase: GamePhase.playing,
        selectedPoint: () => null,
        validMoves: [],
        validMoveTargets: {},
        canUndo: false,
        botMoveFrom: () => null,
        botMoveTo: () => null,
      );
    });

    _socket.on('bot:moved', (data) {
      if (!mounted) return;
      final snapshot =
          GameSnapshot.fromJson(Map<String, dynamic>.from(data['snapshot']));
      final moveData = data['move'] as Map<String, dynamic>?;
      final isBot = data['isBot'] == true;

      if (moveData != null) {
        if (moveData['to'] == 'off') {
          _audio.play(AudioManager.bearOff);
        } else if (moveData['hit'] == true || moveData['isHit'] == true) {
          _audio.play(AudioManager.pieceHit);
          HapticHelper.heavyImpact();
        } else {
          _audio.play(AudioManager.pieceMove);
          HapticHelper.lightImpact();
        }
      } else {
        _audio.play(AudioManager.pieceMove);
      }

      // Parse bot move highlight
      int? moveFrom;
      int? moveTo;
      if (isBot && moveData != null) {
        final fromVal = moveData['from'];
        final toVal = moveData['to'];
        if (fromVal is int) moveFrom = fromVal;
        if (toVal is int) moveTo = toVal;
      }

      state = state.copyWith(
        snapshot: snapshot,
        selectedPoint: () => null,
        validMoves: [],
        validMoveTargets: {},
        canUndo: !isBot && snapshot.currentTurn == state.myColor,
        botMoveFrom: () => moveFrom,
        botMoveTo: () => moveTo,
      );
    });

    _socket.on('bot:moveUndone', (data) {
      if (!mounted) return;
      final snapshot =
          GameSnapshot.fromJson(Map<String, dynamic>.from(data['snapshot']));
      state = state.copyWith(
        snapshot: snapshot,
        selectedPoint: () => null,
        validMoves: [],
        validMoveTargets: {},
        canUndo: false,
      );
    });

    _socket.on('bot:turnEnded', (data) {
      if (!mounted) return;
      final snapshot =
          GameSnapshot.fromJson(Map<String, dynamic>.from(data['snapshot']));
      _audio.play(AudioManager.turnChange);

      state = state.copyWith(
        snapshot: snapshot,
        selectedPoint: () => null,
        validMoves: [],
        validMoveTargets: {},
        canUndo: false,
        botMoveFrom: () => null,
        botMoveTo: () => null,
      );
    });

    _socket.on('bot:gameFinished', (data) {
      if (!mounted) return;
      final winner = data['winner']?.toString();
      final resultType = data['resultType'] ?? 'normal';

      final myColor = state.myColor;
      final won = winner == myColor;

      _audio.play(won ? AudioManager.gameWin : AudioManager.gameLose);
      HapticHelper.success();

      String resultLabel;
      switch (resultType) {
        case 'gammon':
          resultLabel = 'Mars';
          break;
        case 'backgammon':
          resultLabel = 'Kara Mars';
          break;
        case 'resign':
          resultLabel = 'Teslim';
          break;
        default:
          resultLabel = 'Normal';
      }

      final message =
          won ? 'Kazandın! ($resultLabel)' : 'Kaybettin ($resultLabel)';

      if (data['snapshot'] != null) {
        final snapshot =
            GameSnapshot.fromJson(Map<String, dynamic>.from(data['snapshot']));
        state = state.copyWith(
          phase: GamePhase.finished,
          snapshot: snapshot,
          resultMessage: () => message,
        );
      } else {
        state = state.copyWith(
          phase: GamePhase.finished,
          resultMessage: () => message,
        );
      }
    });

    _socket.on('game:error', (data) {
      // Error handling
    });
  }

  void rollDice() {
    if (!state.isMyTurn) return;
    _socket.emit('bot:rollDice');
  }

  void selectPoint(int pointIndex) {
    if (!state.isMyTurn) return;
    if (state.snapshot?.turnPhase != 'moving') return;

    if (pointIndex < 0) {
      state = state.copyWith(
        selectedPoint: () => null,
        validMoveTargets: {},
      );
      return;
    }
    HapticHelper.selectionTap();
    final targets = _computeValidTargets(pointIndex);
    state = state.copyWith(
      selectedPoint: () => pointIndex,
      validMoveTargets: targets,
    );
  }

  Set<int> _computeValidTargets(int fromPoint) {
    final snapshot = state.snapshot;
    if (snapshot == null) return {};
    final myColor = state.myColor;
    if (myColor == null) return {};
    final remaining = snapshot.remainingDice;
    if (remaining == null || remaining.isEmpty) return {};

    final targets = <int>{};
    final usedDice = <int>{};

    for (final die in remaining) {
      if (usedDice.contains(die)) continue;
      usedDice.add(die);

      int targetIndex;
      if (myColor == 'W') {
        targetIndex = fromPoint - die;
      } else {
        targetIndex = fromPoint + die;
      }

      if (targetIndex < 0 || targetIndex >= 24) {
        targets.add(-1);
        continue;
      }

      final targetPoint = snapshot.board.points[targetIndex];
      final opponentColor = myColor == 'W' ? 'B' : 'W';
      if (targetPoint.player == opponentColor && targetPoint.count >= 2) {
        continue;
      }
      targets.add(targetIndex);
    }
    return targets;
  }

  Set<int> computeBarTargets() {
    final snapshot = state.snapshot;
    if (snapshot == null) return {};
    final myColor = state.myColor;
    if (myColor == null) return {};
    final remaining = snapshot.remainingDice;
    if (remaining == null || remaining.isEmpty) return {};

    final targets = <int>{};
    final usedDice = <int>{};

    for (final die in remaining) {
      if (usedDice.contains(die)) continue;
      usedDice.add(die);

      int targetIndex;
      if (myColor == 'W') {
        targetIndex = 24 - die;
      } else {
        targetIndex = die - 1;
      }

      if (targetIndex < 0 || targetIndex >= 24) continue;

      final targetPoint = snapshot.board.points[targetIndex];
      final opponentColor = myColor == 'W' ? 'B' : 'W';
      if (targetPoint.player == opponentColor && targetPoint.count >= 2) {
        continue;
      }
      targets.add(targetIndex);
    }
    return targets;
  }

  void makeMove(int from, int to) {
    if (!state.isMyTurn) return;

    if (state.validMoveTargets.isNotEmpty && !state.validMoveTargets.contains(to)) {
      state = state.copyWith(
        errorMessage: () => 'Buraya oynayamazsın!',
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) state = state.copyWith(errorMessage: () => null);
      });
      return;
    }

    final myColor = state.myColor;
    int dieValue;
    if (myColor == 'W') {
      dieValue = from - to;
    } else {
      dieValue = to - from;
    }
    _socket.emit('bot:move', {'from': from, 'to': to, 'dieValue': dieValue});
    state = state.copyWith(
      selectedPoint: () => null,
      validMoveTargets: {},
    );
  }

  void movePieceFromBar(int to) {
    if (!state.isMyTurn) return;
    final myColor = state.myColor;
    int dieValue;
    if (myColor == 'W') {
      dieValue = 24 - to;
    } else {
      dieValue = to + 1;
    }
    _socket.emit('bot:move', {'from': 'bar', 'to': to, 'dieValue': dieValue});
  }

  void bearOff(int from) {
    if (!state.isMyTurn) return;
    final myColor = state.myColor;
    int dieValue;
    if (myColor == 'W') {
      dieValue = from + 1;
    } else {
      dieValue = 24 - from;
    }
    _socket.emit('bot:move', {'from': from, 'to': 'off', 'dieValue': dieValue});
    state = state.copyWith(selectedPoint: () => null);
  }

  void undoMove() {
    if (!state.canUndo || !state.isMyTurn) return;
    _socket.emit('bot:undoMove');
  }

  void endTurn() {
    final snapshot = state.snapshot;
    if (snapshot != null && state.isMyTurn) {
      final remaining = snapshot.remainingDice;
      if (remaining != null && remaining.isNotEmpty) {
        bool hasValidMove = false;
        final myColor = state.myColor;
        final myBar = snapshot.board.bar[myColor] ?? 0;

        if (myBar > 0) {
          final barTargets = computeBarTargets();
          hasValidMove = barTargets.isNotEmpty;
        } else {
          for (int i = 0; i < 24; i++) {
            final pt = snapshot.board.points[i];
            if (pt.count > 0 && pt.player == myColor) {
              final targets = _computeValidTargets(i);
              if (targets.isNotEmpty) {
                hasValidMove = true;
                break;
              }
            }
          }
        }

        if (hasValidMove) {
          state = state.copyWith(
            errorMessage: () => 'Hâlâ oynayabileceğin hamleler var!',
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) state = state.copyWith(errorMessage: () => null);
          });
          return;
        }
      }
    }
    _socket.emit('bot:endTurn');
  }

  void resign() {
    _socket.emit('bot:resign');
  }

  @override
  void dispose() {
    _socket.off('bot:gameStarted');
    _socket.off('bot:diceRolled');
    _socket.off('game:error');
    _socket.off('bot:moved');
    _socket.off('bot:moveUndone');
    _socket.off('bot:turnEnded');
    _socket.off('bot:gameFinished');
    super.dispose();
  }
}
