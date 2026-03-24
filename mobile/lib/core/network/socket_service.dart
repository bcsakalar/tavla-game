import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class _PendingEmit {
  final String event;
  final dynamic data;

  const _PendingEmit(this.event, this.data);
}

class SocketService {
  io.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Buffer listeners registered before socket is connected
  final Map<String, List<Function(dynamic)>> _pendingListeners = {};
  final List<_PendingEmit> _pendingEmits = [];

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    // Disconnect existing socket if any
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(10)
          .build(),
    );

    // Register any pending listeners that were added before connect()
    for (final entry in _pendingListeners.entries) {
      for (final callback in entry.value) {
        _socket!.on(entry.key, callback);
      }
    }
    _pendingListeners.clear();

    _socket!.onConnect((_) {
      for (final pendingEmit in _pendingEmits) {
        _socket?.emit(pendingEmit.event, pendingEmit.data);
      }
      _pendingEmits.clear();
    });

    _socket!.onDisconnect((_) {
      // Disconnected
    });

    _socket!.onConnectError((data) {
      // Connection error
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _pendingListeners.clear();
    _pendingEmits.clear();
  }

  // Emit events
  void emit(String event, [dynamic data]) {
    if (_socket?.connected ?? false) {
      _socket?.emit(event, data);
      return;
    }

    if (_socket != null) {
      _pendingEmits.add(_PendingEmit(event, data));
    }
  }

  // Listen to events — buffers if socket not yet created
  void on(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);
    } else {
      _pendingListeners.putIfAbsent(event, () => []).add(callback);
    }
  }

  // Remove listeners
  void off(String event) {
    _socket?.off(event);
    _pendingListeners.remove(event);
  }

  // Lobby events
  void joinQueue() => emit('lobby:queue');
  void cancelQueue() => emit('lobby:cancel');
  void getOnlineCount() => emit('lobby:online');

  // Game events
  void rollDice() => emit('game:rollDice');
  void makeMove(Map<String, dynamic> move) => emit('game:move', move);
  void endTurn() => emit('game:endTurn');
  void resign() => emit('game:resign');
  void sendChat(String message) => emit('game:chat', {'message': message});
  void reconnectGame() => emit('game:reconnect');
}
