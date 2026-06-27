class ApiConfig {
  static const String baseUrl =
      'https://ecole-plus-api-production.up.railway.app/api/v1';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
