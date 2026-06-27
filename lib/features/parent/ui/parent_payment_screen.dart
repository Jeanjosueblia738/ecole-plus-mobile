import 'package:flutter/material.dart';
import '../../finance/data/finance_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/parent_api_service.dart';
import '../../../core/network/api_client.dart';
import '../../../services/payment_gateway_service.dart';

class ParentPaymentScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;

  const ParentPaymentScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  ConsumerState<ParentPaymentScreen> createState() =>
      _ParentPaymentScreenState();
}

class _ParentPaymentScreenState extends ConsumerState<ParentPaymentScreen> {
  Map<String, dynamic>? _finance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFinance();
  }

  Future<void> _loadFinance() async {
    try {
      final data = await ParentApiService.getChildFinance(widget.studentId)
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _finance = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(dynamic n) {
    final val = ((n ?? 0) as num).toInt();
    return '${val.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Paiement scolarité',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 20),
              onPressed: _loadFinance),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carte élève
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryBlue, Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(widget.studentName[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(widget.studentName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const Text('Situation financière',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ])),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // Résumé financier
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(children: [
                        _FinRow(
                            label: 'Total dû',
                            value: _fmt(_finance?['resume']?['totalDu']),
                            color: const Color(0xFF1F2937)),
                        const Divider(height: 20),
                        _FinRow(
                            label: 'Total payé',
                            value: _fmt(_finance?['resume']?['totalPaye']),
                            color: successGreen),
                        const Divider(height: 20),
                        _FinRow(
                          label: 'Reste à payer',
                          value: _fmt(_finance?['resume']?['solde']),
                          color: (_finance?['resume']?['solde'] ?? 0) > 0
                              ? dangerRed
                              : successGreen,
                          isBold: true,
                        ),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    // Liste des frais
                    const Text('Détail des frais',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937))),
                    const SizedBox(height: 12),

                    if (_finance?['fees'] == null ||
                        (_finance!['fees'] as List).isEmpty)
                      Center(
                          child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('Aucun frais assigné',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ))
                    else
                      ...(_finance!['fees'] as List).map((f) => _FeeCard(
                            fee: f,
                            studentId: widget.studentId,
                            studentName: widget.studentName,
                            onPaymentDone: _loadFinance,
                          )),

                    const SizedBox(height: 20),
                  ]),
            ),
    );
  }
}

// ── Carte frais avec bouton payer ──────────────────────────────────────────
class _FeeCard extends StatelessWidget {
  final Map<String, dynamic> fee;
  final String studentId;
  final String studentName;
  final VoidCallback onPaymentDone;

  const _FeeCard({
    required this.fee,
    required this.studentId,
    required this.studentName,
    required this.onPaymentDone,
  });

  String _fmt(dynamic n) {
    final val = ((n ?? 0) as num).toInt();
    return '${val.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = fee['isPaid'] as bool? ?? false;
    final feeInfo = fee['fee'] as Map<String, dynamic>?;
    final amountXof = (feeInfo?['amountXof'] ?? 0) as num;
    final amountPaid = (fee['amountPaid'] ?? 0) as num;
    final remaining = amountXof - amountPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid
              ? successGreen.withValues(alpha: 0.3)
              : dangerRed.withValues(alpha: 0.2),
        ),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPaid
                  ? successGreen.withValues(alpha: 0.1)
                  : primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPaid ? Icons.check_circle_outline : Icons.receipt_long_outlined,
              color: isPaid ? successGreen : primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(feeInfo?['label'] ?? 'Frais',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(_fmt(amountXof),
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ])),
          if (isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('✓ Payé',
                  style: TextStyle(
                      color: successGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
        ]),
        if (!isPaid && remaining > 0) ...[
          const SizedBox(height: 12),
          if (amountPaid > 0) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Déjà payé',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(_fmt(amountPaid),
                  style: const TextStyle(fontSize: 12, color: successGreen)),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Reste à payer',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(_fmt(remaining),
                  style: const TextStyle(
                      fontSize: 12,
                      color: dangerRed,
                      fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _MobileMoneyPaymentSheet(
                      studentId: studentId,
                      studentName: studentName,
                      feeId: fee['feeId'] as String,
                      feeLabel: feeInfo?['label'] ?? 'Frais',
                      montantXof: remaining.toInt(),
                    ),
                  ),
                );
                if (result == true) onPaymentDone();
              },
              icon: const Icon(Icons.phone_android, size: 18),
              label: Text('Payer ${_fmt(remaining)} via Mobile Money'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

// ── Écran paiement Mobile Money ────────────────────────────────────────────
class _MobileMoneyPaymentSheet extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String feeId;
  final String feeLabel;
  final int montantXof;

  const _MobileMoneyPaymentSheet({
    required this.studentId,
    required this.studentName,
    required this.feeId,
    required this.feeLabel,
    required this.montantXof,
  });

  @override
  State<_MobileMoneyPaymentSheet> createState() =>
      _MobileMoneyPaymentSheetState();
}

class _MobileMoneyPaymentSheetState extends State<_MobileMoneyPaymentSheet> {
  MobileMoneyOperator _operator = MobileMoneyOperator.orangeMoney;
  final _phoneCtrl = TextEditingController();
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _fmt(int n) =>
      '${n.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} FCFA';

  Future<void> _pay() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez saisir le numéro Mobile Money');
      return;
    }
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      // 1. Simuler la transaction Mobile Money
      final result = await PaymentGatewayService.processMobileMoney(
        operator: _operator,
        phoneNumber: _phoneCtrl.text.trim(),
        montant: widget.montantXof.toDouble(),
        reference: 'ECOLE-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;

      if (result.success) {
        // 2. Enregistrer dans l'API Railway
        try {
          await ApiClient.instance.post('/finance/payments', data: {
            'studentId': widget.studentId,
            'feeId': widget.feeId,
            'amountXof': widget.montantXof,
            'paymentMode': _operator == MobileMoneyOperator.orangeMoney
                ? 'orange_money'
                : _operator == MobileMoneyOperator.wave
                    ? 'wave'
                    : _operator == MobileMoneyOperator.mtnMoney
                        ? 'mtn_money'
                        : 'moov_money',
            'transactionId': result.transactionId,
            'phoneNumber': _phoneCtrl.text.trim(),
          });
        } catch (e) {
          debugPrint('ECOLE+ paiement API: $e');
        }

        if (!mounted) return;
        setState(() => _processing = false);
        _showSuccess(result.transactionId!);
      } else {
        setState(() {
          _processing = false;
          _error = result.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _error = e.toString();
      });
    }
  }

  void _showSuccess(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                color: successGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline,
                color: successGreen, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Paiement réussi !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${_fmt(widget.montantXof)} payés via ${_operator.label}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Réf: $transactionId',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child:
                  const Text('Fermer', style: TextStyle(color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Paiement Mobile Money',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Résumé paiement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Frais', style: TextStyle(color: Color(0xFF6B7280))),
                Text(widget.feeLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Élève', style: TextStyle(color: Color(0xFF6B7280))),
                Text(widget.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
              const Divider(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Montant',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(_fmt(widget.montantXof),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: primaryBlue)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // Choix opérateur
          const Text('Opérateur Mobile Money',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ...MobileMoneyOperator.values.map((op) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _operator = op),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _operator == op
                          ? primaryBlue.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _operator == op
                            ? primaryBlue
                            : Colors.grey.shade200,
                        width: _operator == op ? 2 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.phone_android,
                          color: _operator == op
                              ? primaryBlue
                              : Colors.grey.shade400),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(op.label,
                              style: TextStyle(
                                fontWeight: _operator == op
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _operator == op
                                    ? primaryBlue
                                    : const Color(0xFF1F2937),
                              ))),
                      if (_operator == op)
                        const Icon(Icons.check_circle,
                            color: primaryBlue, size: 20),
                    ]),
                  ),
                ),
              )),

          const SizedBox(height: 16),

          // Numéro de téléphone
          const Text('Numéro Mobile Money',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '07 XX XX XX XX',
              prefixText: '+225 ',
              prefixStyle: const TextStyle(color: Color(0xFF1F2937)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryBlue, width: 2),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dangerRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: dangerRed.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: dangerRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style:
                            const TextStyle(color: dangerRed, fontSize: 13))),
              ]),
            ),
          ],

          const SizedBox(height: 24),

          // Bouton payer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processing ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _processing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Traitement en cours...',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        ])
                  : Text('Payer ${_fmt(widget.montantXof)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              '🔒 Paiement sécurisé — Vos données sont protégées',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ── Widgets utilitaires ────────────────────────────────────────────────────
class _FinRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isBold;

  const _FinRow(
      {required this.label,
      required this.value,
      required this.color,
      this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
      Text(value,
          style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color)),
    ]);
  }
}
