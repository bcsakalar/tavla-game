import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavla_online/core/network/api_client.dart';
import 'package:tavla_online/core/network/socket_service.dart';
import 'package:tavla_online/core/storage/auth_storage.dart';
import 'package:tavla_online/features/auth/providers/auth_provider.dart';

void main() {
  group('AuthNotifier', () {
    test('should ignore stale startup auth check when login begins first', () async {
      final hasTokensCompleter = Completer<bool>();
      final apiClient = _FakeApiClient(
        loginHandler: (_, __) async => {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'user': _userJson,
        },
      );
      final storage = _FakeAuthStorage(
        hasTokensHandler: () => hasTokensCompleter.future,
      );
      final notifier = AuthNotifier(apiClient, storage, _FakeSocketService());

      final loginFuture = notifier.login('demo', 'password123');
      await Future<void>.delayed(Duration.zero);
      hasTokensCompleter.complete(false);
      await loginFuture;
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user?.username, 'demo');
    });

    test('should ignore stale startup auth check when register begins first', () async {
      final hasTokensCompleter = Completer<bool>();
      final apiClient = _FakeApiClient(
        registerHandler: (_, __, ___) async => {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'user': _userJson,
        },
      );
      final storage = _FakeAuthStorage(
        hasTokensHandler: () => hasTokensCompleter.future,
      );
      final notifier = AuthNotifier(apiClient, storage, _FakeSocketService());

      final registerFuture = notifier.register('demo', 'demo@example.com', 'password123');
      await Future<void>.delayed(Duration.zero);
      hasTokensCompleter.complete(false);
      await registerFuture;
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user?.username, 'demo');
    });

    test('should authenticate when socket connection fails during login', () async {
      final apiClient = _FakeApiClient(
        loginHandler: (_, __) async => {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'user': _userJson,
        },
      );
      final storage = _FakeAuthStorage();
      final socket = _FakeSocketService(connectError: Exception('socket failed'));
      final notifier = AuthNotifier(apiClient, storage, socket);

      await Future<void>.delayed(Duration.zero);
      await notifier.login('demo', 'password123');
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user?.username, 'demo');
      expect(socket.connectCalls, 1);
      expect(await storage.getAccessToken(), 'access-token');
    });

    test('should expose api error when login fails', () async {
      final apiClient = _FakeApiClient(
        loginHandler: (_, __) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            response: Response(
              requestOptions: RequestOptions(path: '/api/auth/login'),
              statusCode: 401,
              data: {'error': 'Kullanıcı adı veya şifre hatalı'},
            ),
          );
        },
      );
      final notifier = AuthNotifier(apiClient, _FakeAuthStorage(), _FakeSocketService());

      await Future<void>.delayed(Duration.zero);
      await notifier.login('demo', 'wrong-password');

      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.error, 'Kullanıcı adı veya şifre hatalı');
    });

    test('should expose timeout error when login never completes', () async {
      final apiClient = _FakeApiClient(
        loginHandler: (_, __) => Completer<Map<String, dynamic>>().future,
      );
      final notifier = AuthNotifier(apiClient, _FakeAuthStorage(), _FakeSocketService());

      await Future<void>.delayed(Duration.zero);
      await notifier.login('demo', 'password123');

      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.error, 'Sunucu yanit vermedi, lutfen tekrar deneyin');
    });
  });
}

const Map<String, dynamic> _userJson = {
  'id': 1,
  'username': 'demo',
  'email': 'demo@example.com',
  'elo_rating': 1200,
  'total_wins': 0,
  'total_losses': 0,
  'total_draws': 0,
  'total_gammons': 0,
  'total_backgammons': 0,
};

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.loginHandler, this.registerHandler});

  final Future<Map<String, dynamic>> Function(String identifier, String password)? loginHandler;
  final Future<Map<String, dynamic>> Function(String username, String email, String password)? registerHandler;

  @override
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    return loginHandler!(identifier, password);
  }

  @override
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    return registerHandler!(username, email, password);
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    throw DioException(
      requestOptions: RequestOptions(path: '/api/users/me'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/users/me'),
        statusCode: 401,
      ),
    );
  }
}

class _FakeAuthStorage extends AuthStorage {
  _FakeAuthStorage({this.hasTokensHandler});

  String? _accessToken;
  String? _refreshToken;
  final Future<bool> Function()? hasTokensHandler;

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<bool> hasTokens() async {
    if (hasTokensHandler != null) {
      return hasTokensHandler!();
    }

    return _accessToken != null;
  }
}

class _FakeSocketService extends SocketService {
  _FakeSocketService({this.connectError});

  final Object? connectError;
  int connectCalls = 0;
  bool disconnected = false;

  @override
  Future<void> connect() async {
    connectCalls += 1;
    if (connectError != null) {
      throw connectError!;
    }
  }

  @override
  void disconnect() {
    disconnected = true;
  }
}