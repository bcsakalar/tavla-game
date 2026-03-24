import 'dart:async';
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
  Timer? _botAnimTimer;

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

      if (isBot && (moveFrom != null || moveTo != null)) {
        // Phase 1: Show bot move highlight BEFORE updating board
        _botAnimTimer?.cancel();
        state = state.copyWith(
          botMoveFrom: () => moveFrom,
          botMoveTo: () => moveTo,
          animatingBotMove: true,
        );

        // Phase 2: After delay, update board state
        _botAnimTimer = Timer(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          state = state.copyWith(
            snapshot: snapshot,
            selectedPoint: () => null,
            validMoves: [],
            validMoveTargets: {},
            canUndo: false,
            animatingBotMove: false,
          );

          // Phase 3: Clear highlight after another short delay
          _botAnimTimer = Timer(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            state = state.copyWith(
              botMoveFrom: () => null,
              botMoveTo: () => null,
            );
          });
        });
      } else {
        // Player's own move — update immediately
        state = state.copyWith(
          snapshot: snapshot,
          selectedPoint: () => null,
          validMoves: [],
          validMoveTargets: {},
          canUndo: !isBot && snapshot.currentTurn == state.myColor,
          botMoveFrom: () => moveFrom,
          botMoveTo: () => moveTo,
        );
      }
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
      final message = _extractSocketErrorMessage(data);
      if (message != null) {
        _showTemporaryError(message);
      }
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
    final sourcePoint = snapshot.board.points[fromPoint];
    if (sourcePoint.count == 0 || sourcePoint.player != myColor) return {};
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
        if (_isValidBearOffDie(snapshot, myColor, fromPoint, die)) {
          targets.add(-1);
        }
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

  bool _isValidBearOffDie(
    GameSnapshot snapshot,
    String myColor,
    int fromPoint,
    int dieValue,
  ) {
    if (!_canBearOff(snapshot, myColor) || !_isHomePoint(fromPoint, myColor)) {
      return false;
    }

    final pointNumber = _pointNumberForPlayer(fromPoint, myColor);
    if (pointNumber == dieValue) {
      return true;
    }

    if (pointNumber < dieValue) {
      return _highestOccupiedHomePoint(snapshot, myColor) == fromPoint;
    }

    return false;
  }

  bool _canBearOff(GameSnapshot snapshot, String myColor) {
    final board = snapshot.board;
    final bar = board.bar[myColor] ?? 0;
    if (bar > 0) return false;
    final borneOff = board.borneOff[myColor] ?? 0;
    int homeCount = borneOff;
    if (myColor == 'W') {
      for (int i = 0; i < 6; i++) {
        if (board.points[i].player == myColor) homeCount += board.points[i].count;
      }
    } else {
      for (int i = 18; i < 24; i++) {
        if (board.points[i].player == myColor) homeCount += board.points[i].count;
      }
    }
    return homeCount == 15;
  }

  bool _isHomePoint(int pointIndex, String myColor) {
    return myColor == 'W'
        ? pointIndex >= 0 && pointIndex <= 5
        : pointIndex >= 18 && pointIndex < 24;
  }

  int _pointNumberForPlayer(int pointIndex, String myColor) {
    return myColor == 'W' ? pointIndex + 1 : 24 - pointIndex;
  }

  int _highestOccupiedHomePoint(GameSnapshot snapshot, String myColor) {
    if (myColor == 'W') {
      for (int i = 5; i >= 0; i--) {
        final point = snapshot.board.points[i];
        if (point.count > 0 && point.player == myColor) {
          return i;
        }
      }
    } else {
      for (int i = 18; i < 24; i++) {
        final point = snapshot.board.points[i];
        if (point.count > 0 && point.player == myColor) {
          return i;
        }
      }
    }

    return -1;
  }

  int? _resolveBearOffDie(GameSnapshot snapshot, String myColor, int fromPoint) {
    final remaining = snapshot.remainingDice;
    if (remaining == null || remaining.isEmpty) return null;

    final pointNumber = _pointNumberForPlayer(fromPoint, myColor);
    int? higherDie;

    for (final die in remaining) {
      if (!_isValidBearOffDie(snapshot, myColor, fromPoint, die)) continue;
      if (die == pointNumber) {
        return die;
      }
      if (higherDie == null || die < higherDie) {
        higherDie = die;
      }
    }

    return higherDie;
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
      _showTemporaryError('Buraya oynayamazsın!');
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

    final snapshot = state.snapshot;
    final myColor = state.myColor;
    if (snapshot == null || myColor == null) return;

    final dieValue = _resolveBearOffDie(snapshot, myColor, from);
    if (dieValue == null) {
      _showTemporaryError('Bu taşı bu zarla toplayamazsın!');
      return;
    }

    _socket.emit('bot:move', {'from': from, 'to': 'off', 'dieValue': dieValue});
    state = state.copyWith(
      selectedPoint: () => null,
      validMoveTargets: {},
    );
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
          _showTemporaryError('Hâlâ oynayabileceğin hamleler var!');
          return;
        }
      }
    }
    _socket.emit('bot:endTurn');
  }

  String? _extractSocketErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final value = data['message'] ?? data['error'];
      if (value != null) return value.toString();
    } else if (data is Map) {
      final value = data['message'] ?? data['error'];
      if (value != null) return value.toString();
    } else if (data is String && data.isNotEmpty) {
      return data;
    }

    return null;
  }

  void _showTemporaryError(String message) {
    if (!mounted) return;
    state = state.copyWith(errorMessage: () => message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && state.errorMessage == message) {
        state = state.copyWith(errorMessage: () => null);
      }
    });
  }

  void resign() {
    _socket.emit('bot:resign');
  }

  @override
  void dispose() {
    _botAnimTimer?.cancel();
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
