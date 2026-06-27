import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/finance/data/finance_model.dart';
import '../../features/student/data/student.dart';
import 'student_provider.dart';

// ─── Frais scolaires ──────────────────────────────────────────────────────
class FeeNotifier extends StateNotifier<List<SchoolFee>> {
  static const _key = 'school_fees';

  FeeNotifier() : super(_defaultFees());

  static List<SchoolFee> _defaultFees() {
    final now = DateTime.now();
    return [
      SchoolFee(
        id: 'f1',
        type: FeeType.inscription,
        label: 'Frais d\'inscription 2024-2025',
        montant: 25000,
        trimestre: 'Annuel',
        dateEcheance: DateTime(now.year, 10, 31),
      ),
      SchoolFee(
        id: 'f2',
        type: FeeType.scolarite,
        label: 'Scolarité 1er trimestre',
        montant: 75000,
        trimestre: '1er',
        dateEcheance: DateTime(now.year, 11, 30),
      ),
      SchoolFee(
        id: 'f3',
        type: FeeType.scolarite,
        label: 'Scolarité 2ème trimestre',
        montant: 75000,
        trimestre: '2ème',
        dateEcheance: DateTime(now.year + 1, 2, 28),
      ),
      SchoolFee(
        id: 'f4',
        type: FeeType.scolarite,
        label: 'Scolarité 3ème trimestre',
        montant: 75000,
        trimestre: '3ème',
        dateEcheance: DateTime(now.year + 1, 5, 31),
      ),
      SchoolFee(
        id: 'f5',
        type: FeeType.transport,
        label: 'Transport scolaire',
        montant: 30000,
        trimestre: 'Annuel',
        obligatoire: false,
        dateEcheance: DateTime(now.year, 10, 31),
      ),
      SchoolFee(
        id: 'f6',
        type: FeeType.examen,
        label: 'Frais examens BEPC/BAC',
        montant: 15000,
        trimestre: 'Annuel',
        dateEcheance: DateTime(now.year + 1, 3, 31),
      ),
    ];
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      final List decoded = jsonDecode(data);
      state = decoded.map((e) => SchoolFee.fromJson(e)).toList();
    }
  }

  Future<void> add(SchoolFee fee) async {
    state = [...state, fee];
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((f) => f.id != id).toList();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(state.map((f) => f.toJson()).toList()));
  }
}

final feeProvider = StateNotifierProvider<FeeNotifier, List<SchoolFee>>(
  (ref) => FeeNotifier(),
);

// ─── Paiements ────────────────────────────────────────────────────────────
class PaymentNotifier extends StateNotifier<List<Payment>> {
  static const _key = 'payments';
  static int _receiptCounter = 1000;

  PaymentNotifier() : super([]);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      final List decoded = jsonDecode(data);
      state = decoded.map((e) => Payment.fromJson(e)).toList();
      if (state.isNotEmpty) _receiptCounter = state.length + 1000;
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
    _receiptCounter++;
    final payment = Payment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: studentId,
      studentName: studentName,
      className: className,
      feeId: feeId,
      feeLabel: feeLabel,
      montant: montant,
      method: method,
      status: method == PaymentMethod.mobileMoney
          ? PaymentStatus.enAttente
          : PaymentStatus.valide,
      date: DateTime.now(),
      operatorName: operatorName,
      phoneNumber: phoneNumber,
      transactionId: transactionId,
      chequeNumber: chequeNumber,
      receiptNumber: 'REC-${_receiptCounter.toString().padLeft(6, '0')}',
    );
    state = [...state, payment];
    await _save();
    return payment;
  }

  Future<void> validatePayment(String id) async {
    state = [
      for (final p in state)
        if (p.id == id)
          Payment(
            id: p.id,
            studentId: p.studentId,
            studentName: p.studentName,
            className: p.className,
            feeId: p.feeId,
            feeLabel: p.feeLabel,
            montant: p.montant,
            method: p.method,
            status: PaymentStatus.valide,
            date: p.date,
            operatorName: p.operatorName,
            phoneNumber: p.phoneNumber,
            transactionId: p.transactionId,
            chequeNumber: p.chequeNumber,
            receiptNumber: p.receiptNumber,
          )
        else
          p,
    ];
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(state.map((p) => p.toJson()).toList()));
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, List<Payment>>(
  (ref) => PaymentNotifier(),
);

// ─── Providers dérivés ────────────────────────────────────────────────────

// Paiements d'un élève
final paymentsByStudentProvider =
    Provider.family<List<Payment>, String>((ref, studentId) {
  return ref
      .watch(paymentProvider)
      .where((p) => p.studentId == studentId)
      .toList();
});

// Paiements en attente (Mobile Money à valider)
final pendingPaymentsProvider = Provider<List<Payment>>((ref) {
  return ref
      .watch(paymentProvider)
      .where((p) => p.status == PaymentStatus.enAttente)
      .toList();
});

// Stats financières globales
final financeStatsProvider = Provider<Map<String, double>>((ref) {
  final payments = ref.watch(paymentProvider);
  final fees = ref.watch(feeProvider);
  final students = ref.watch(studentProvider);

  final totalEncaisse = payments
      .where((p) => p.status == PaymentStatus.valide)
      .fold(0.0, (s, p) => s + p.montant);

  final totalDu =
      fees.where((f) => f.obligatoire).fold(0.0, (s, f) => s + f.montant) *
          students.length;

  return {
    'encaisse': totalEncaisse,
    'du': totalDu,
    'enAttente': payments
        .where((p) => p.status == PaymentStatus.enAttente)
        .fold(0.0, (s, p) => s + p.montant),
    'tauxRecouvrement': totalDu > 0 ? totalEncaisse / totalDu : 0,
  };
});

// Résumé financier par élève
final studentFinanceSummaryProvider =
    Provider.family<StudentFinanceSummary, Student>((ref, student) {
  final fees = ref.watch(feeProvider);
  final payments = ref.watch(paymentsByStudentProvider(student.id));

  final totalDu =
      fees.where((f) => f.obligatoire).fold(0.0, (s, f) => s + f.montant);

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
