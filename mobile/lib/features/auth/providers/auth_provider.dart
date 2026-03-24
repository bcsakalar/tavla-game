import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../shared/models/user.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final socketServiceProvider = Provider<SocketService>((ref) => SocketService());
final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(apiClientProvider),
    ref.read(authStorageProvider),
    ref.read(socketServiceProvider),
  );
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, User? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const Duration _authRequestTimeout = Duration(seconds: 15);

  final ApiClient _api;
  final AuthStorage _storage;
  final SocketService _socket;
  int _authOperationId = 0;

  AuthNotifier(this._api, this._storage, this._socket)
      : super(const AuthState()) {
    unawaited(checkAuth());
  }

  Future<void> checkAuth() async {
    final operationId = _startAuthOperation();
    final hasTokens = await _storage.hasTokens();
    if (_isStaleOperation(operationId)) return;

    if (!hasTokens) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final data = await _withAuthTimeout(_api.getProfile());
      if (_isStaleOperation(operationId)) return;

      final user = User.fromJson(data);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      unawaited(_connectSocketSafely());
    } catch (_) {
      if (_isStaleOperation(operationId)) return;

      await _storage.clearTokens();
      if (_isStaleOperation(operationId)) return;

      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String identifier, String password) async {
    final operationId = _startAuthOperation();
    state = const AuthState(status: AuthStatus.loading);

    try {
      final data = await _withAuthTimeout(_api.login(identifier, password));
      if (_isStaleOperation(operationId)) return;

      await _storage.saveTokens(data['accessToken'], data['refreshToken']);
      if (_isStaleOperation(operationId)) return;

      final user = User.fromJson(data['user']);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      unawaited(_connectSocketSafely());
    } catch (e) {
      if (_isStaleOperation(operationId)) return;

      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, error: message);
    }
  }

  Future<void> register(String username, String email, String password) async {
    final operationId = _startAuthOperation();
    state = const AuthState(status: AuthStatus.loading);

    try {
      final data = await _withAuthTimeout(
        _api.register(username, email, password),
      );
      if (_isStaleOperation(operationId)) return;

      await _storage.saveTokens(data['accessToken'], data['refreshToken']);
      if (_isStaleOperation(operationId)) return;

      final user = User.fromJson(data['user']);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      unawaited(_connectSocketSafely());
    } catch (e) {
      if (_isStaleOperation(operationId)) return;

      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, error: message);
    }
  }

  Future<void> logout() async {
    _startAuthOperation();
    _socket.disconnect();
    await _storage.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  int _startAuthOperation() {
    _authOperationId += 1;
    return _authOperationId;
  }

  bool _isStaleOperation(int operationId) {
    return !mounted || operationId != _authOperationId;
  }

  Future<void> _connectSocketSafely() async {
    try {
      await _socket.connect();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _withAuthTimeout(
    Future<Map<String, dynamic>> request,
  ) {
    return request.timeout(
      _authRequestTimeout,
      onTimeout: () => throw TimeoutException('Auth request timed out'),
    );
  }

  String _extractError(dynamic e) {
    if (e is TimeoutException) {
      return 'Sunucu yanit vermedi, lutfen tekrar deneyin';
    }

    try {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('error')) {
          return data['error'].toString();
        }
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return 'Sunucuya bağlanılamadı';
        }
      }
    } catch (_) {}
    if (e is Error) {
      return e.toString();
    }
    if (e is Exception) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    return 'Bir hata oluştu';
  }
}
