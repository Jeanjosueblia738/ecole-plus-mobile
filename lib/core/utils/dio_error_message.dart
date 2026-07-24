import 'package:dio/dio.dart';

/// True si l'échec est purement réseau (file offline OK) — jamais sur 4xx/403.
bool isOfflineEnqueueableError(Object e) {
  if (e is! DioException) return false;
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return true;
    default:
      return false;
  }
}

/// Message utilisateur lisible depuis une [DioException].
String dioErrorMessage(DioException e, {String fallback = 'Erreur réseau'}) {
  final data = e.response?.data;
  if (data is Map) {
    final msg = data['message'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    if (msg is List && msg.isNotEmpty) {
      return msg.map((m) => m.toString()).join(', ');
    }
  }
  if (data is String && data.trim().isNotEmpty) return data.trim();

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Délai dépassé — vérifiez votre connexion';
    case DioExceptionType.connectionError:
      return 'Pas de connexion au serveur';
    case DioExceptionType.cancel:
      return 'Requête annulée';
    default:
      break;
  }
  return e.message?.trim().isNotEmpty == true ? e.message!.trim() : fallback;
}
