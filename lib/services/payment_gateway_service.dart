import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../features/finance/data/finance_model.dart';

// ─── Résultat d'une transaction Mobile Money ──────────────────────────────
class MobileMoneyResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final String? status;
  final String? message;

  const MobileMoneyResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    this.status,
    this.message,
  });
}

String _providerApiCode(MobileMoneyOperator operator) => switch (operator) {
      MobileMoneyOperator.orangeMoney => 'ORANGE_MONEY',
      MobileMoneyOperator.wave => 'WAVE',
      MobileMoneyOperator.mtnMoney => 'MTN_MOMO',
      MobileMoneyOperator.moov => 'MOOV_MONEY',
    };

/// Passerelle Mobile Money → API Nest `/payments/fees/initiate`
class PaymentGatewayService {
  static const notAvailableMessage =
      'Paiement Mobile Money indisponible. '
      'L’école doit configurer son compte marchand (Paramètres → Mobile Money).';

  static Future<MobileMoneyResult> processMobileMoney({
    required MobileMoneyOperator operator,
    required String phoneNumber,
    required double montant,
    required String reference,
    required String studentId,
    required String feeId,
  }) async {
    final validationError = _validatePhone(operator, phoneNumber);
    if (validationError != null) {
      return MobileMoneyResult(success: false, errorMessage: validationError);
    }

    try {
      final response = await ApiClient.instance.post(
        '/payments/fees/initiate',
        data: {
          'provider': _providerApiCode(operator),
          'studentId': studentId,
          'feeId': feeId,
          'amountXof': montant.round(),
          'payerPhone': phoneNumber.trim(),
        },
      );
      final data = response.data as Map<String, dynamic>? ?? {};
      final status = data['status']?.toString() ?? 'PENDING';
      final ok = status.toUpperCase() == 'SUCCESS';
      return MobileMoneyResult(
        success: ok,
        status: status,
        transactionId:
            data['transactionId']?.toString() ?? data['externalId']?.toString(),
        message: data['message']?.toString(),
        errorMessage: ok
            ? null
            : (data['message']?.toString() ??
                data['ussdHint']?.toString() ??
                'Paiement en attente de confirmation opérateur.'),
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message']?.toString())
          : null;
      return MobileMoneyResult(
        success: false,
        errorMessage: msg ?? notAvailableMessage,
      );
    } catch (_) {
      return const MobileMoneyResult(
        success: false,
        errorMessage: notAvailableMessage,
      );
    }
  }

  static String? _validatePhone(MobileMoneyOperator operator, String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');

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
