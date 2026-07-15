/// API base URL via --dart-define=API_BASE_URL=...
/// Exemple: flutter run --dart-define=API_BASE_URL=https://...
class ApiConfig {
  static const String _fromDefine = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromDefine.isNotEmpty) {
      return _fromDefine;
    }
    // Prod Railway par défaut ; local: --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
    return const String.fromEnvironment(
      'DEFAULT_API_BASE_URL',
      defaultValue:
          'https://ecole-plus-api-production.up.railway.app/api/v1',
    );
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
