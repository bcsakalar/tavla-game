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
  final ApiClient _api;
  final AuthStorage _storage;
  final SocketService _socket;

  AuthNotifier(this._api, this._storage, this._socket)
      : super(const AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final hasTokens = await _storage.hasTokens();
    if (!hasTokens) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final data = await _api.getProfile();
      final user = User.fromJson(data);
      await _socket.connect();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _storage.clearTokens();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String identifier, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final data = await _api.login(identifier, password);
      await _storage.saveTokens(data['accessToken'], data['refreshToken']);
      final user = User.fromJson(data['user']);
      await _socket.connect();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, error: message);
    }
  }

  Future<void> register(String username, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final data = await _api.register(username, email, password);
      await _storage.saveTokens(data['accessToken'], data['refreshToken']);
      final user = User.fromJson(data['user']);
      await _socket.connect();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, error: message);
    }
  }

  Future<void> logout() async {
    _socket.disconnect();
    await _storage.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _extractError(dynamic e) {
    try {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('error')) {
          return data['error'].toString();
        }
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
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
