import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  static const Set<String> _publicAuthPaths = {
    '/api/auth/login',
    '/api/auth/register',
    '/api/auth/refresh',
  };

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_isPublicAuthPath(options.path)) {
          handler.next(options);
          return;
        }

        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            !_isPublicAuthPath(error.requestOptions.path)) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the request with new token
            final token = await _storage.read(key: 'access_token');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConfig.apiBaseUrl}/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        await _storage.write(key: 'access_token', value: response.data['accessToken']);
        await _storage.write(key: 'refresh_token', value: response.data['refreshToken']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  bool _isPublicAuthPath(String path) {
    return _publicAuthPaths.contains(path);
  }

  // Auth
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final response = await _dio.post('/api/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'identifier': identifier,
      'password': password,
    });
    return response.data;
  }

  // Users
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/api/users/me');
    return response.data;
  }

  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final response = await _dio.get('/api/users/$userId');
    return response.data;
  }

  Future<List<dynamic>> getUserGames(int userId, {int limit = 20, int offset = 0}) async {
    final response = await _dio.get('/api/users/$userId/games', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    return response.data;
  }

  // Games
  Future<Map<String, dynamic>> getGame(int gameId) async {
    final response = await _dio.get('/api/games/$gameId');
    return response.data;
  }

  // Leaderboard
  Future<List<dynamic>> getLeaderboard({int limit = 50, int offset = 0}) async {
    final response = await _dio.get('/api/leaderboard', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    return response.data;
  }
}
