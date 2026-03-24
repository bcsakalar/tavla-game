import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavla_online/core/network/api_client.dart';
import 'package:tavla_online/core/network/socket_service.dart';
import 'package:tavla_online/core/storage/auth_storage.dart';
import 'package:tavla_online/features/auth/providers/auth_provider.dart';

void main() {
  group('AuthNotifier', () {
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
  _FakeApiClient({this.loginHandler});

  final Future<Map<String, dynamic>> Function(String identifier, String password)? loginHandler;

  @override
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    return loginHandler!(identifier, password);
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
  String? _accessToken;
  String? _refreshToken;

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
  Future<bool> hasTokens() async => _accessToken != null;
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