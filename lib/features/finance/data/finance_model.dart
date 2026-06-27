// ─── Types de frais (réalité ivoirienne) ──────────────────────────────────
enum FeeType {
  scolarite,
  inscription,
  transport,
  cantine,
  examen,
  divers,
}

extension FeeTypeLabel on FeeType {
  String get label => switch (this) {
        FeeType.scolarite => 'Scolarité',
        FeeType.inscription => 'Inscription',
        FeeType.transport => 'Transport',
        FeeType.cantine => 'Cantine',
        FeeType.examen => 'Examens',
        FeeType.divers => 'Divers',
      };
}

// ─── Opérateurs Mobile Money CI ───────────────────────────────────────────
enum MobileMoneyOperator { orangeMoney, wave, mtnMoney, moov }

extension MobileMoneyLabel on MobileMoneyOperator {
  String get label => switch (this) {
        MobileMoneyOperator.orangeMoney => 'Orange Money',
        MobileMoneyOperator.wave => 'Wave',
        MobileMoneyOperator.mtnMoney => 'MTN Money',
        MobileMoneyOperator.moov => 'Moov Money',
      };

  String get prefix => switch (this) {
        MobileMoneyOperator.orangeMoney => '07',
        MobileMoneyOperator.wave => '01',
        MobileMoneyOperator.mtnMoney => '05',
        MobileMoneyOperator.moov => '01',
      };
}

// ─── Méthode de paiement ──────────────────────────────────────────────────
enum PaymentMethod { especes, mobileMoney, cheque }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.especes => 'Espèces',
        PaymentMethod.mobileMoney => 'Mobile Money',
        PaymentMethod.cheque => 'Chèque',
      };
}

// ─── Statut du paiement ───────────────────────────────────────────────────
enum PaymentStatus { enAttente, valide, echoue, rembourse }

extension PaymentStatusLabel on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.enAttente => 'En attente',
        PaymentStatus.valide => 'Validé',
        PaymentStatus.echoue => 'Échoué',
        PaymentStatus.rembourse => 'Remboursé',
      };
}

// ─── Frais configuré pour un type ─────────────────────────────────────────
class SchoolFee {
  final String id;
  final FeeType type;
  final String label;
  final double montant; // en XOF
  final String trimestre; // '1er' | '2ème' | '3ème' | 'Annuel'
  final String? classLevel; // null = tous niveaux
  final bool obligatoire;
  final DateTime dateEcheance;

  const SchoolFee({
    required this.id,
    required this.type,
    required this.label,
    required this.montant,
    required this.trimestre,
    this.classLevel,
    this.obligatoire = true,
    required this.dateEcheance,
  });

  String get montantFormate =>
      '${montant.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} FCFA';

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'montant': montant,
        'trimestre': trimestre,
        'classLevel': classLevel,
        'obligatoire': obligatoire,
        'dateEcheance': dateEcheance.toIso8601String(),
      };

  factory SchoolFee.fromJson(Map<String, dynamic> json) => SchoolFee(
        id: json['id'],
        type: FeeType.values.byName(json['type']),
        label: json['label'],
        montant: (json['montant'] as num).toDouble(),
        trimestre: json['trimestre'],
        classLevel: json['classLevel'],
        obligatoire: json['obligatoire'] ?? true,
        dateEcheance: DateTime.parse(json['dateEcheance']),
      );
}

// ─── Paiement effectué ────────────────────────────────────────────────────
class Payment {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String feeId;
  final String feeLabel;
  final double montant;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime date;
  final String? operatorName; // Orange Money, Wave...
  final String? phoneNumber; // numéro Mobile Money
  final String? transactionId; // référence opérateur
  final String? chequeNumber;
  final String receiptNumber; // numéro de reçu ECOLE+

  const Payment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.feeId,
    required this.feeLabel,
    required this.montant,
    required this.method,
    required this.status,
    required this.date,
    this.operatorName,
    this.phoneNumber,
    this.transactionId,
    this.chequeNumber,
    required this.receiptNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'className': className,
        'feeId': feeId,
        'feeLabel': feeLabel,
        'montant': montant,
        'method': method.name,
        'status': status.name,
        'date': date.toIso8601String(),
        'operatorName': operatorName,
        'phoneNumber': phoneNumber,
        'transactionId': transactionId,
        'chequeNumber': chequeNumber,
        'receiptNumber': receiptNumber,
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'],
        studentId: json['studentId'],
        studentName: json['studentName'],
        className: json['className'],
        feeId: json['feeId'],
        feeLabel: json['feeLabel'],
        montant: (json['montant'] as num).toDouble(),
        method: PaymentMethod.values.byName(json['method']),
        status: PaymentStatus.values.byName(json['status']),
        date: DateTime.parse(json['date']),
        operatorName: json['operatorName'],
        phoneNumber: json['phoneNumber'],
        transactionId: json['transactionId'],
        chequeNumber: json['chequeNumber'],
        receiptNumber: json['receiptNumber'],
      );

  // Formater le montant en XOF
  String get montantFormate =>
      '${montant.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
}

// ─── Résumé financier par élève ───────────────────────────────────────────
class StudentFinanceSummary {
  final String studentId;
  final String studentName;
  final double totalDu;
  final double totalPaye;
  final List<Payment> payments;

  const StudentFinanceSummary({
    required this.studentId,
    required this.studentName,
    required this.totalDu,
    required this.totalPaye,
    required this.payments,
  });

  double get solde => totalDu - totalPaye;
  bool get estAJour => solde <= 0;
}
