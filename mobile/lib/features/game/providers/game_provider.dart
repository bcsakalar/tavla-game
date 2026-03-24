import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/haptic/haptic_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/game_state.dart';

final gameProvider = StateNotifierProvider.autoDispose<GameNotifier, GamePlayState>((ref) {
  final socket = ref.read(socketServiceProvider);
  return GameNotifier(socket);
});

enum GamePhase { loading, initialRoll, playing, finished }

class ChatMessage {
  final String username;
  final String message;
  final DateTime timestamp;

  const ChatMessage({
    required this.username,
    required this.message,
    required this.timestamp,
  });
}

class EmojiReaction {
  final String emoji;
  final String fromColor;
  final DateTime timestamp;

  const EmojiReaction({
    required this.emoji,
    required this.fromColor,
    required this.timestamp,
  });
}

class GamePlayState {
  final GamePhase phase;
  final GameSnapshot? snapshot;
  final String? myColor;
  final int? selectedPoint;
  final List<Map<String, dynamic>> validMoves;
  final Set<int> validMoveTargets;
  final List<ChatMessage> chatMessages;
  final int turnTimer;
  final int maxTimer;
  final String? resultMessage;
  final int? eloChange;
  final bool canUndo;
  final EmojiReaction? lastEmoji;
  final bool isBotGame;
  final String? errorMessage;
  final int? botMoveFrom;
  final int? botMoveTo;
  final String? opponentUsername;
  final int? opponentUserId;
  final int? opponentElo;
  final bool animatingBotMove;

  const GamePlayState({
    this.phase = GamePhase.loading,
    this.snapshot,
    this.myColor,
    this.selectedPoint,
    this.validMoves = const [],
    this.validMoveTargets = const {},
    this.chatMessages = const [],
    this.turnTimer = 60,
    this.maxTimer = 60,
    this.resultMessage,
    this.eloChange,
    this.canUndo = false,
    this.lastEmoji,
    this.isBotGame = false,
    this.errorMessage,
    this.botMoveFrom,
    this.botMoveTo,
    this.opponentUsername,
    this.opponentUserId,
    this.opponentElo,
    this.animatingBotMove = false,
  });

  bool get isMyTurn => snapshot?.currentTurn == myColor;

  GamePlayState copyWith({
    GamePhase? phase,
    GameSnapshot? snapshot,
    String? myColor,
    int? Function()? selectedPoint,
    List<Map<String, dynamic>>? validMoves,
    Set<int>? validMoveTargets,
    List<ChatMessage>? chatMessages,
    int? turnTimer,
    int? maxTimer,
    String? Function()? resultMessage,
    int? Function()? eloChange,
    bool? canUndo,
    EmojiReaction? Function()? lastEmoji,
    bool? isBotGame,
    String? Function()? errorMessage,
    int? Function()? botMoveFrom,
    int? Function()? botMoveTo,
    String? Function()? opponentUsername,
    int? Function()? opponentUserId,
    int? Function()? opponentElo,
    bool? animatingBotMove,
  }) {
    return GamePlayState(
      phase: phase ?? this.phase,
      snapshot: snapshot ?? this.snapshot,
      myColor: myColor ?? this.myColor,
      selectedPoint: selectedPoint != null ? selectedPoint() : this.selectedPoint,
      validMoves: validMoves ?? this.validMoves,
      validMoveTargets: validMoveTargets ?? this.validMoveTargets,
      chatMessages: chatMessages ?? this.chatMessages,
      turnTimer: turnTimer ?? this.turnTimer,
      maxTimer: maxTimer ?? this.maxTimer,
      resultMessage: resultMessage != null ? resultMessage() : this.resultMessage,
      eloChange: eloChange != null ? eloChange() : this.eloChange,
      canUndo: canUndo ?? this.canUndo,
      lastEmoji: lastEmoji != null ? lastEmoji() : this.lastEmoji,
      isBotGame: isBotGame ?? this.isBotGame,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      botMoveFrom: botMoveFrom != null ? botMoveFrom() : this.botMoveFrom,
      botMoveTo: botMoveTo != null ? botMoveTo() : this.botMoveTo,
      opponentUsername: opponentUsername != null ? opponentUsername() : this.opponentUsername,
      opponentUserId: opponentUserId != null ? opponentUserId() : this.opponentUserId,
      opponentElo: opponentElo != null ? opponentElo() : this.opponentElo,
      animatingBotMove: animatingBotMove ?? this.animatingBotMove,
    );
  }
}

class GameNotifier extends StateNotifier<GamePlayState> {
  final SocketService _socket;
  final AudioManager _audio = AudioManager();
  Timer? _turnTimer;

  GameNotifier(this._socket) : super(const GamePlayState()) {
    _setupListeners();
  }

  void initGame(Map<String, dynamic> gameData, int myUserId) {
    final snapshotData = gameData['snapshot'] as Map<String, dynamic>?;
    if (snapshotData == null || snapshotData['board'] == null) return;
    final snapshot = GameSnapshot.fromJson(snapshotData);
    final myColor = snapshot.whitePlayerId == myUserId.toString() ? 'W' : 'B';
    const timerMax = AppConfig.moveTimerSeconds;

    // Extract opponent info from match data
    final whiteData = gameData['white'] as Map<String, dynamic>?;
    final blackData = gameData['black'] as Map<String, dynamic>?;
    final opponentData = myColor == 'W' ? blackData : whiteData;

    final phase = snapshot.state == 'initial_roll'
        ? GamePhase.initialRoll
        : snapshot.state == 'finished'
            ? GamePhase.finished
            : GamePhase.playing;

    state = state.copyWith(
      phase: phase,
      snapshot: snapshot,
      myColor: myColor,
      maxTimer: timerMax,
      turnTimer: timerMax,
      opponentUsername: () => opponentData?['username']?.toString(),
      opponentUserId: () => opponentData?['userId'] != null
          ? int.tryParse(opponentData!['userId'].toString())
          : null,
      opponentElo: () => opponentData?['elo'] != null
          ? int.tryParse(opponentData!['elo'].toString())
          : null,
    );

    if (snapshot.currentTurn == myColor) {
      _startTurnTimer();
    }
  }

  void _setupListeners() {
    _socket.on('game:diceRolled', (data) {
      if (!mounted) return;
      final snapshot = GameSnapshot.fromJson(Map<String, dynamic>.from(data['snapshot']));
      _audio.play(AudioManager.diceRoll);
      HapticHelper.mediumImpact();
      state = state.copyWith(
        snapshot: snapshot,
        phase: snapshot.state == 'initial_roll'
            ? GamePhase.initialRoll
            : GamePhase.playing,
        selectedPoint: () => null,
        validMoves: [],
        validMoveTargets: {},
        canUndo: false,
      );

      if (snapshot.currentTurn == state.myColor) {
        _startTurnTimer();
      }
    });

    _socket.on('game:moved', (data) {
      if (!mounted) return;
      final snapshot = GameSnapshot.fromJson(Map<String, dynamic>.from(data['snapshot']));

      // Determine what kind of move happened
      final moveData = data['move'] as Map<String, dynamic>?;
      if (moveData != null) {
        if (moveData['to'] == 'off') {
          _audio.play(AudioManager.bearOff);
        } else if (moveData['hit'] == true) {
          _audio.play(AudioManager.pieceHit);
          HapticHelper.heavyImpact();
        } else {
          _audio.play(AudioManager.pieceMove);
          HapticHelper.lightImpact();
        }
      } else {
        _audio.play(AudioManager.pieceMove);
      }

      state = state.copyWith(
        snapshot: snapshot,
        selectedPoint: () => null,
        validMoves: [],
        validMoveTargets: {},
        canUndo: snapshot.currentTurn == state.myColor,
      );
    });

    _socket.on('game:moveUndone', (data) {
      if (!mounted) return;
      final snapshot = GameSnapshot.fromJson(Map<String, dynamic>.from(data['snapshot']));
      state = state.copyWith(
        snapshot: snapshot,
        selectedPoint: () => null,
        validMoves: [],
        validMoveTargets: {},
        canUndo: false,
      );
    });

    _socket.on('game:timerStart', (data) {
      if (!mounted) return;
      // Server syncs timer — reset our local timer
      final seconds = data['seconds'] as int? ?? AppConfig.moveTimerSeconds;
      _turnTimer?.cancel();
      state = state.copyWith(turnTimer: seconds, maxTimer: seconds);
      if (state.isMyTurn) {
        _startTurnTimer();
      }
    });

    _socket.on('game:turnEnded', (data) {
      if (!mounted) return;
      final snapshot = GameSnapshot.fromJson(Map<String, dynamic>.from(data['snapshot']));
      _turnTimer?.cancel();
      _audio.play(AudioManager.turnChange);

      state = state.copyWith(
        snapshot: snapshot,
        turnTimer: state.maxTimer,
        selectedPoint: () => null,
        validMoves: [],
        validMoveTargets: {},
        canUndo: false,
      );

      if (snapshot.currentTurn == state.myColor) {
        _startTurnTimer();
      }
    });

    _socket.on('game:finished', (data) {
      if (!mounted) return;
      _turnTimer?.cancel();
      final winner = data['winner']?.toString();
      final resultType = data['resultType'] ?? 'normal';
      final eloChanges = data['eloChanges'] as Map<String, dynamic>?;

      final myColor = state.myColor;
      final won = winner == myColor;
      final eloChange = eloChanges != null
          ? (myColor == 'W' ? eloChanges['white'] : eloChanges['black']) as int?
          : null;

      _audio.play(won ? AudioManager.gameWin : AudioManager.gameLose);
      HapticHelper.success();

      final resultLabel = _getResultLabel(resultType);
      final message = won ? 'Kazandın! ($resultLabel)' : 'Kaybettin ($resultLabel)';

      if (data['snapshot'] != null) {
        final snapshot = GameSnapshot.fromJson(Map<String, dynamic>.from(data['snapshot']));
        state = state.copyWith(
          phase: GamePhase.finished,
          snapshot: snapshot,
          resultMessage: () => message,
          eloChange: () => eloChange,
        );
      } else {
        state = state.copyWith(
          phase: GamePhase.finished,
          resultMessage: () => message,
          eloChange: () => eloChange,
        );
      }
    });

    _socket.on('game:emoji', (data) {
      if (!mounted) return;
      final emoji = EmojiReaction(
        emoji: data['emoji'] ?? '',
        fromColor: data['from'] ?? '',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(lastEmoji: () => emoji);
      // Auto-clear after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(lastEmoji: () => null);
        }
      });
    });

    _socket.on('game:chatMessage', (data) {
      if (!mounted) return;
      _audio.play(AudioManager.chatMessage);
      final msg = ChatMessage(
        username: data['username'] ?? '',
        message: data['message'] ?? '',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        chatMessages: [...state.chatMessages, msg],
      );
    });

    _socket.on('game:error', (data) {
      // Error handling — can show snackbar in UI
    });
  }

  void rollDice() {
    if (!state.isMyTurn) return;
    _socket.rollDice();
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

    final bearOffAllowed = _canBearOff(snapshot, myColor);
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
        if (bearOffAllowed) targets.add(-1);
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

    // Check if target is valid
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

    _socket.makeMove({'from': from, 'to': to, 'dieValue': dieValue});
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

    _socket.makeMove({'from': 'bar', 'to': to, 'dieValue': dieValue});
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

    _socket.makeMove({'from': from, 'to': 'off', 'dieValue': dieValue});
    state = state.copyWith(selectedPoint: () => null);
  }

  void undoMove() {
    if (!state.canUndo || !state.isMyTurn) return;
    _socket.emit('game:undoMove');
  }

  void sendEmoji(String emoji) {
    _socket.emit('game:emoji', {'emoji': emoji});
    _audio.play(AudioManager.buttonTap);
  }

  void endTurn() {
    // Check locally if there are valid moves remaining
    final snapshot = state.snapshot;
    if (snapshot != null && state.isMyTurn) {
      final remaining = snapshot.remainingDice;
      if (remaining != null && remaining.isNotEmpty) {
        // Check all points for valid moves
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
    _socket.endTurn();
  }

  void resign() {
    _socket.resign();
  }

  void sendChat(String message) {
    if (message.trim().isEmpty) return;
    _socket.sendChat(message.trim());
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    final max = state.maxTimer;
    state = state.copyWith(turnTimer: max);
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final newTime = state.turnTimer - 1;
      if (newTime == 10) {
        _audio.play(AudioManager.timerWarning);
        HapticHelper.mediumImpact();
      } else if (newTime <= 5 && newTime > 0) {
        _audio.play(AudioManager.timerCritical);
        HapticHelper.lightImpact();
      }
      if (newTime <= 0) {
        _turnTimer?.cancel();
        state = state.copyWith(turnTimer: 0);
        return;
      }
      state = state.copyWith(turnTimer: newTime);
    });
  }

  String _getResultLabel(String type) {
    switch (type) {
      case 'gammon':
        return 'Mars';
      case 'backgammon':
        return 'Üç Mars';
      case 'resign':
        return 'Teslim';
      case 'timeout':
        return 'Süre Doldu';
      case 'disconnect':
        return 'Bağlantı Koptu';
      default:
        return 'Normal';
    }
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _socket.off('game:diceRolled');
    _socket.off('game:moved');
    _socket.off('game:moveUndone');
    _socket.off('game:timerStart');
    _socket.off('game:turnEnded');
    _socket.off('game:finished');
    _socket.off('game:emoji');
    _socket.off('game:chatMessage');
    _socket.off('game:error');
    super.dispose();
  }
}
