import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/socket_service.dart';
import '../../auth/providers/auth_provider.dart';

final lobbyProvider = StateNotifierProvider<LobbyNotifier, LobbyState>((ref) {
  final socket = ref.read(socketServiceProvider);
  return LobbyNotifier(socket);
});

enum QueueStatus { idle, searching, matched }

class LobbyState {
  final QueueStatus status;
  final int onlineCount;
  final int searchSeconds;
  final Map<String, dynamic>? matchData;

  const LobbyState({
    this.status = QueueStatus.idle,
    this.onlineCount = 0,
    this.searchSeconds = 0,
    this.matchData,
  });

  LobbyState copyWith({
    QueueStatus? status,
    int? onlineCount,
    int? searchSeconds,
    Map<String, dynamic>? matchData,
  }) {
    return LobbyState(
      status: status ?? this.status,
      onlineCount: onlineCount ?? this.onlineCount,
      searchSeconds: searchSeconds ?? this.searchSeconds,
      matchData: matchData ?? this.matchData,
    );
  }
}

class LobbyNotifier extends StateNotifier<LobbyState> {
  final SocketService _socket;
  Timer? _searchTimer;
  Timer? _onlineTimer;

  LobbyNotifier(this._socket) : super(const LobbyState()) {
    _setupListeners();
    _startOnlinePolling();
  }

  void _setupListeners() {
    _socket.on('lobby:onlineCount', (data) {
      if (!mounted) return;
      final count = data is int ? data : (data is Map ? data['count'] ?? 0 : 0);
      state = state.copyWith(onlineCount: count);
    });

    _socket.on('game:start', (data) {
      if (!mounted) return;
      _searchTimer?.cancel();
      state = state.copyWith(
        status: QueueStatus.matched,
        matchData: Map<String, dynamic>.from(data),
      );
    });
  }

  void _startOnlinePolling() {
    _socket.getOnlineCount();
    _onlineTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _socket.getOnlineCount();
    });
  }

  void joinQueue() {
    _socket.joinQueue();
    state = state.copyWith(status: QueueStatus.searching, searchSeconds: 0);
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      state = state.copyWith(searchSeconds: state.searchSeconds + 1);
    });
  }

  void cancelQueue() {
    _socket.cancelQueue();
    _searchTimer?.cancel();
    state = state.copyWith(status: QueueStatus.idle, searchSeconds: 0);
  }

  void clearMatch() {
    state = state.copyWith(status: QueueStatus.idle, matchData: null, searchSeconds: 0);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _onlineTimer?.cancel();
    _socket.off('lobby:onlineCount');
    _socket.off('game:start');
    super.dispose();
  }
}
