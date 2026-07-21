import '../features/finance/data/finance_model.dart';

// ─── Résultat d'une transaction Mobile Money ──────────────────────────────
class MobileMoneyResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;

  const MobileMoneyResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
  });
}

// ─── Passerelle Mobile Money CI ───────────────────────────────────────────
// Orange Money CI / Wave / MTN MoMo / Moov ne sont pas encore intégrés.
// Ne jamais simuler un succès ni enregistrer un faux paiement comme réel.
class PaymentGatewayService {
  static const notAvailableMessage =
      'Paiement Mobile Money non disponible — passerelle non intégrée. '
      'Effectuez le paiement à l\'école ou contactez la scolarité.';

  /// Tente un paiement Mobile Money. Pour l'instant : validation du numéro
  /// puis refus explicite (aucune simulation de succès).
  static Future<MobileMoneyResult> processMobileMoney({
    required MobileMoneyOperator operator,
    required String phoneNumber,
    required double montant,
    required String reference,
  }) async {
    final validationError = _validatePhone(operator, phoneNumber);
    if (validationError != null) {
      return MobileMoneyResult(success: false, errorMessage: validationError);
    }

    return const MobileMoneyResult(
      success: false,
      errorMessage: notAvailableMessage,
    );
  }

  // Validation numéros CI par opérateur
  static String? _validatePhone(MobileMoneyOperator operator, String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');

    // Format CI : +225 XX XX XX XX XX (10 chiffres hors indicatif)
    if (cleaned.length != 10 && cleaned.length != 13) {
      return 'Numéro invalide — format attendu : 07 XX XX XX XX';
    }

    final prefix = cleaned.length == 13
        ? cleaned.substring(3, 5)
        : cleaned.substring(0, 2);

    final validPrefixes = switch (operator) {
      MobileMoneyOperator.orangeMoney => ['07'],
      MobileMoneyOperator.wave => ['01', '07'],
      MobileMoneyOperator.mtnMoney => ['05'],
      MobileMoneyOperator.moov => ['01'],
    };

    if (!validPrefixes.contains(prefix)) {
      return 'Ce numéro ne correspond pas à ${operator.label}';
    }
    return null;
  }
}
