import 'package:flutter/foundation.dart';
import '../features/notifications/data/sms_store.dart';
import '../features/notifications/data/sms_record.dart';

class SmsService {
  /// Aucune passerelle SMS configurée — n'enregistre jamais comme « Envoyé ».
  /// Retourne `null` et journalise un échec local honnête.
  static Future<String?> sendSms({
    required String recipient,
    required String message,
  }) async {
    final now = DateTime.now();

    await SmsStore.add(
      SmsRecord(
        recipient: recipient,
        message: message,
        date: now,
        status: 'Échoué',
      ),
    );

    debugPrint(
        '📨 SMS non envoyé (passerelle absente) → $recipient : $message');
    return null;
  }
}
