import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/finance/data/finance_model.dart';
import '../../features/student/data/student.dart';
import '../services/finance_api_service.dart';
import '../utils/school_year.dart';
import 'student_provider.dart';

SchoolFee schoolFeeFromApi(Map<String, dynamic> json) {
  return SchoolFee(
    id: json['id']?.toString() ?? '',
    type: (json['type']?.toString().trim().isNotEmpty == true)
        ? json['type'].toString().trim()
        : 'Scolarité',
    label: json['label']?.toString() ?? '',
    montant: (json['amountXof'] as num?)?.toDouble() ??
        (json['montant'] as num?)?.toDouble() ??
        0,
    trimestre: json['year']?.toString() ?? json['trimestre']?.toString() ?? '',
    classLevel: json['level'] as String?,
    obligatoire: true,
    dateEcheance: DateTime.tryParse(json['dueDate']?.toString() ?? '') ??
        DateTime.now(),
  );
}

PaymentMethod _mapPaymentMode(dynamic raw) {
  final s = (raw?.toString() ?? '').toLowerCase();
  if (s.contains('cheque') || s.contains('chèque')) return PaymentMethod.cheque;
  if (s.contains('orange') ||
      s.contains('wave') ||
      s.contains('mtn') ||
      s.contains('moov') ||
      s.contains('mobile')) {
    return PaymentMethod.mobileMoney;
  }
  return PaymentMethod.especes;
}

// ─── Frais scolaires (API) ────────────────────────────────────────────────
class FeeNotifier extends StateNotifier<List<SchoolFee>> {
  FeeNotifier() : super([]);

  bool loading = false;
  String? error;

  Future<void> load({String? year}) async {
    loading = true;
    error = null;
    try {
      final raw = await FinanceApiService.getFees(year: year);
      state = raw
          .map((e) => schoolFeeFromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      error = 'Impossible de charger les frais';
      state = [];
    } finally {
      loading = false;
    }
  }

  Future<void> add(SchoolFee fee) async {
    await FinanceApiService.createFee({
      'label': fee.label,
      'amountXof': fee.montant,
      'dueDate': fee.dateEcheance.toIso8601String().split('T').first,
      'year': currentSchoolYear(),
      'type': fee.type.trim().isEmpty ? 'Scolarité' : fee.type.trim(),
      if (fee.classLevel != null) 'level': fee.classLevel,
    });
    await load(year: currentSchoolYear());
  }

  Future<void> remove(String id) async {
    state = state.where((f) => f.id != id).toList();
  }
}

final feeProvider = StateNotifierProvider<FeeNotifier, List<SchoolFee>>(
  (ref) => FeeNotifier(),
);

// ─── Paiements (API) ──────────────────────────────────────────────────────
class PaymentNotifier extends StateNotifier<List<Payment>> {
  PaymentNotifier() : super([]);

  String? error;

  Future<void> loadForStudent(String studentId) async {
    error = null;
    try {
      final data = await FinanceApiService.getStudentFinance(studentId);
      final fees = (data['fees'] as List?) ?? [];
      final payments = <Payment>[];
      for (final row in fees) {
        final map = Map<String, dynamic>.from(row as Map);
        final fee = map['fee'] is Map
            ? Map<String, dynamic>.from(map['fee'] as Map)
            : <String, dynamic>{};
        final amountPaid = (map['amountPaid'] as num?)?.toDouble() ?? 0;
        if (amountPaid <= 0) continue;
        payments.add(Payment(
          id: map['id']?.toString() ?? '',
          studentId: studentId,
          studentName: '',
          className: '',
          feeId: fee['id']?.toString() ?? map['feeId']?.toString() ?? '',
          feeLabel: fee['label']?.toString() ?? '',
          montant: amountPaid,
          method: _mapPaymentMode(map['paymentMode']),
          status: map['isPaid'] == true
              ? PaymentStatus.valide
              : PaymentStatus.enAttente,
          date: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
              DateTime.now(),
          receiptNumber: map['receiptNo']?.toString() ??
              'REC-${map['id']?.toString().substring(0, 6) ?? '------'}',
          transactionId: map['transactionId'] as String?,
          phoneNumber: map['phoneNumber'] as String?,
        ));
      }
      state = [
        ...state.where((p) => p.studentId != studentId),
        ...payments,
      ];
    } catch (_) {
      // Ne pas conserver d'anciens paiements comme s'ils étaient à jour.
      state = state.where((p) => p.studentId != studentId).toList();
      error = 'Impossible de charger les paiements';
    }
  }

  Future<Payment> addPayment({
    required String studentId,
    required String studentName,
    required String className,
    required String feeId,
    required String feeLabel,
    required double montant,
    required PaymentMethod method,
    String? operatorName,
    String? phoneNumber,
    String? transactionId,
    String? chequeNumber,
  }) async {
    final mode = switch (method) {
      PaymentMethod.cheque => 'cheque',
      PaymentMethod.mobileMoney => (operatorName ?? 'mobile_money')
          .toLowerCase()
          .replaceAll(' ', '_'),
      PaymentMethod.especes => 'especes',
    };

    final res = await FinanceApiService.recordPayment({
      'studentId': studentId,
      'feeId': feeId,
      'amountPaid': montant,
      'paymentMode': mode,
      if (transactionId != null) 'transactionId': transactionId,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (chequeNumber != null) 'receiptNo': chequeNumber,
    });

    final payment = Payment(
      id: res['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: studentId,
      studentName: studentName,
      className: className,
      feeId: feeId,
      feeLabel: feeLabel,
      montant: montant,
      method: method,
      status: PaymentStatus.valide,
      date: DateTime.now(),
      operatorName: operatorName,
      phoneNumber: phoneNumber,
      transactionId: transactionId,
      chequeNumber: chequeNumber,
      receiptNumber: res['receiptNo']?.toString() ??
          'REC-${DateTime.now().millisecondsSinceEpoch % 1000000}',
    );
    state = [...state, payment];
    return payment;
  }

  /// Pas d'endpoint de validation côté API — ne pas simuler un succès serveur.
  Future<bool> validatePayment(String id) async {
    return false;
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, List<Payment>>(
  (ref) => PaymentNotifier(),
);

final paymentsByStudentProvider =
    Provider.family<List<Payment>, String>((ref, studentId) {
  return ref
      .watch(paymentProvider)
      .where((p) => p.studentId == studentId)
      .toList();
});

final pendingPaymentsProvider = Provider<List<Payment>>((ref) {
  return ref
      .watch(paymentProvider)
      .where((p) => p.status == PaymentStatus.enAttente)
      .toList();
});

final financeStatsProvider = Provider<Map<String, double>>((ref) {
  final payments = ref.watch(paymentProvider);
  final fees = ref.watch(feeProvider);
  final students = ref.watch(studentProvider);

  final totalEncaisse = payments
      .where((p) => p.status == PaymentStatus.valide)
      .fold(0.0, (s, p) => s + p.montant);

  final totalDu =
      fees.fold(0.0, (s, f) => s + f.montant) * (students.isEmpty ? 1 : 1);

  return {
    'encaisse': totalEncaisse,
    'du': totalDu,
    'enAttente': payments
        .where((p) => p.status == PaymentStatus.enAttente)
        .fold(0.0, (s, p) => s + p.montant),
    'tauxRecouvrement': totalDu > 0 ? totalEncaisse / totalDu : 0,
  };
});

final studentFinanceSummaryProvider =
    Provider.family<StudentFinanceSummary, Student>((ref, student) {
  final fees = ref.watch(feeProvider);
  final payments = ref.watch(paymentsByStudentProvider(student.id));

  final totalDu = fees.fold(0.0, (s, f) => s + f.montant);
  final totalPaye = payments
      .where((p) => p.status == PaymentStatus.valide)
      .fold(0.0, (s, p) => s + p.montant);

  return StudentFinanceSummary(
    studentId: student.id,
    studentName: student.fullName,
    totalDu: totalDu,
    totalPaye: totalPaye,
    payments: payments,
  );
});
