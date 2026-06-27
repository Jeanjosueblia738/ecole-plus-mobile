import 'package:flutter/foundation.dart';
import '../features/notifications/data/sms_store.dart';
import '../features/notifications/data/sms_record.dart';

class SmsService {
  static Future<String> sendSms({
    required String recipient,
    required String message,
  }) async {
    final now = DateTime.now();
    final smsId = now.millisecondsSinceEpoch.toString();

    // 1️⃣ Enregistrement dans l'historique local
    await SmsStore.add(
      SmsRecord(
        recipient: recipient,
        message: message,
        date: now,
        status: 'Envoyé',
      ),
    );

    // 2️⃣ Log de debug uniquement en mode développement
    // ✅ debugPrint est autorisé en production contrairement à print()
    debugPrint('📨 SMS simulé → $recipient : $message');

    return smsId;
  }
}
