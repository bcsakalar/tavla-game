import 'package:flutter_test/flutter_test.dart';
import 'package:tavla_online/core/haptic/haptic_helper.dart';
import 'package:tavla_online/core/network/socket_service.dart';
import 'package:tavla_online/features/game/providers/bot_game_provider.dart';
import 'package:tavla_online/features/game/providers/game_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HapticHelper.enabled = false;
  });

  tearDownAll(() {
    HapticHelper.enabled = true;
  });

  group('GameNotifier', () {
    test('should not allow overshoot target when a higher home point is occupied', () {
      final socket = _FakeSocketService();
      final notifier = GameNotifier(socket);
      addTearDown(notifier.dispose);

      notifier.initGame(
        _buildGameData(
          _buildSnapshot(
            whitePoints: {
              5: 1,
              2: 14,
            },
            remainingDice: const [6],
          ),
        ),
        1,
      );

      notifier.selectPoint(2);

      expect(notifier.state.validMoveTargets.contains(-1), isFalse);
    });

    test('should allow overshoot target when checker is on highest occupied home point', () {
      final socket = _FakeSocketService();
      final notifier = GameNotifier(socket);
      addTearDown(notifier.dispose);

      notifier.initGame(
        _buildGameData(
          _buildSnapshot(
            whitePoints: {
              4: 1,
              2: 14,
            },
            remainingDice: const [6],
          ),
        ),
        1,
      );

      notifier.selectPoint(4);

      expect(notifier.state.validMoveTargets.contains(-1), isTrue);
    });

    test('should emit higher die when overshoot bear off is valid', () {
      final socket = _FakeSocketService();
      final notifier = GameNotifier(socket);
      addTearDown(notifier.dispose);

      notifier.initGame(
        _buildGameData(
          _buildSnapshot(
            whitePoints: {
              4: 1,
              2: 14,
            },
            remainingDice: const [6],
          ),
        ),
        1,
      );

      notifier.bearOff(4);

      expect(socket.events.single.event, 'game:move');
      expect(socket.events.single.data, {
        'from': 4,
        'to': 'off',
        'dieValue': 6,
      });
    });

    test('should show error when overshoot bear off is invalid', () {
      final socket = _FakeSocketService();
      final notifier = GameNotifier(socket);
      addTearDown(notifier.dispose);

      notifier.initGame(
        _buildGameData(
          _buildSnapshot(
            whitePoints: {
              5: 1,
              2: 14,
            },
            remainingDice: const [6],
          ),
        ),
        1,
      );

      notifier.bearOff(2);

      expect(socket.events, isEmpty);
      expect(notifier.state.errorMessage, 'Bu taşı bu zarla toplayamazsın!');
    });

    test('should expose socket game errors through provider state', () {
      final socket = _FakeSocketService();
      final notifier = GameNotifier(socket);
      addTearDown(notifier.dispose);

      socket.trigger('game:error', {'message': 'Geçersiz hamle'});

      expect(notifier.state.errorMessage, 'Geçersiz hamle');
    });
  });

  group('BotGameNotifier', () {
    test('should mirror overshoot validity rules in bot mode', () {
      final socket = _FakeSocketService();
      final notifier = BotGameNotifier(socket);
      addTearDown(notifier.dispose);

      notifier.startBotGame('easy', 1);
      socket.trigger('bot:gameStarted', {
        'snapshot': _buildSnapshot(
          whitePoints: {
            4: 1,
            2: 14,
          },
          remainingDice: const [6],
        ),
      });

      notifier.selectPoint(4);

      expect(notifier.state.validMoveTargets.contains(-1), isTrue);
    });
  });
}

class _FakeSocketService extends SocketService {
  final Map<String, List<Function(dynamic)>> _listeners = {};
  final List<_SocketEvent> events = [];

  @override
  void on(String event, Function(dynamic) callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  @override
  void off(String event) {
    _listeners.remove(event);
  }

  @override
  void emit(String event, [dynamic data]) {
    events.add(_SocketEvent(event, data));
  }

  @override
  void makeMove(Map<String, dynamic> move) {
    events.add(_SocketEvent('game:move', move));
  }

  @override
  void endTurn() {
    events.add(const _SocketEvent('game:endTurn', null));
  }

  @override
  void rollDice() {
    events.add(const _SocketEvent('game:rollDice', null));
  }

  @override
  void resign() {
    events.add(const _SocketEvent('game:resign', null));
  }

  void trigger(String event, dynamic data) {
    final listeners = _listeners[event];
    if (listeners == null) return;
    for (final listener in List<Function(dynamic)>.from(listeners)) {
      listener(data);
    }
  }
}

class _SocketEvent {
  final String event;
  final dynamic data;

  const _SocketEvent(this.event, this.data);
}

Map<String, dynamic> _buildGameData(Map<String, dynamic> snapshot) {
  return {
    'snapshot': snapshot,
    'white': {
      'userId': '1',
      'username': 'white',
      'elo': '1200',
    },
    'black': {
      'userId': '2',
      'username': 'black',
      'elo': '1200',
    },
  };
}

Map<String, dynamic> _buildSnapshot({
  Map<int, int> whitePoints = const {},
  Map<int, int> blackPoints = const {},
  List<int> remainingDice = const [6],
}) {
  final points = List.generate(24, (_) => <String, dynamic>{'count': 0, 'player': null});

  whitePoints.forEach((index, count) {
    points[index] = {'count': count, 'player': 'W'};
  });

  blackPoints.forEach((index, count) {
    points[index] = {'count': count, 'player': 'B'};
  });

  return {
    'state': 'playing',
    'board': {
      'points': points,
      'bar': {'W': 0, 'B': 0},
      'borneOff': {'W': 0, 'B': 0},
    },
    'currentTurn': 'W',
    'turnPhase': 'moving',
    'dice': remainingDice,
    'remainingDice': remainingDice,
    'moveNumber': 1,
    'whitePlayerId': '1',
    'blackPlayerId': '2',
  };
}