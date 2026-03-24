class AppConfig {
  /// Production URL as default — override with --dart-define for local dev:
  /// flutter run --dart-define=API_BASE_URL=http://localhost:3006 --dart-define=SOCKET_URL=http://localhost:3006
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tavla.berkecansakalar.com',
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://tavla.berkecansakalar.com',
  );

  static const int moveTimerSeconds = 60;
  static const int reconnectWindowSeconds = 60;
}
