import 'dart:math';
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

// ─── Service simulation paiements Mobile Money CI ─────────────────────────
// En production : intégrer les SDK officiels
// Orange Money CI : https://developer.orange.com/apis/om-civieng
// Wave CI         : API Wave Business
// MTN Money CI    : MTN MoMo API
class PaymentGatewayService {
  // Simulation d'une transaction Mobile Money
  // Délai simulé : 2-4 secondes (comme une vraie transaction)
  static Future<MobileMoneyResult> processMobileMoney({
    required MobileMoneyOperator operator,
    required String phoneNumber,
    required double montant,
    required String reference,
  }) async {
    // Validation numéro selon opérateur CI
    final validationError = _validatePhone(operator, phoneNumber);
    if (validationError != null) {
      return MobileMoneyResult(success: false, errorMessage: validationError);
    }

    // Simulation délai réseau
    await Future.delayed(Duration(milliseconds: 2000 + Random().nextInt(2000)));

    // Simulation taux de succès 90%
    final isSuccess = Random().nextDouble() > 0.1;

    if (isSuccess) {
      return MobileMoneyResult(
        success: true,
        transactionId: _generateTransactionId(operator),
      );
    } else {
      return MobileMoneyResult(
        success: false,
        errorMessage:
            'Solde insuffisant ou transaction refusée par ${operator.label}',
      );
    }
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

  static String _generateTransactionId(MobileMoneyOperator op) {
    final prefix = switch (op) {
      MobileMoneyOperator.orangeMoney => 'OM',
      MobileMoneyOperator.wave => 'WV',
      MobileMoneyOperator.mtnMoney => 'MT',
      MobileMoneyOperator.moov => 'MV',
    };
    final rand = Random().nextInt(999999999).toString().padLeft(9, '0');
    return '$prefix$rand';
  }
}
