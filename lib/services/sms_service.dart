import 'package:flutter/foundation.dart';

/// Stub local — ne simule plus d’envoi réussi.
/// L’envoi SMS réel est côté serveur ; le mobile gère packs/crédits via [SmsApiService].
class SmsService {
  static Future<String?> sendSms({
    required String recipient,
    required String message,
  }) async {
    debugPrint(
        'SMS local désactivé (passerelle absente) → $recipient : $message');
    return null;
  }
}
