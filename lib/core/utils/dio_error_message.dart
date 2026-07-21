import 'package:dio/dio.dart';

/// Message utilisateur en français à partir d'une [DioException].
String dioErrorMessage(DioException e, {String fallback = 'Erreur de connexion'}) {
  final data = e.response?.data;
  if (data is Map && data['message'] != null) {
    final msg = data['message'];
    if (msg is List && msg.isNotEmpty) {
      return msg.first.toString();
    }
    return msg.toString();
  }
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      'Délai de connexion dépassé. Réessayez.',
    DioExceptionType.connectionError =>
      'Impossible de joindre le serveur. Vérifiez votre connexion.',
    DioExceptionType.badResponse =>
      'Erreur serveur (${e.response?.statusCode ?? '?'})',
    _ => fallback,
  };
}
