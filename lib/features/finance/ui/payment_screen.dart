import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/receipt_pdf_service.dart';
import '../data/finance_model.dart';
import 'mobile_money_screen.dart';
import 'package:printing/printing.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String? _selectedStudentId;
  String? _selectedFeeId;
  PaymentMethod _method = PaymentMethod.especes;
  final _chequeCtrl = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (ref.read(studentProvider).isEmpty) {
        await ref.read(studentProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _chequeCtrl.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    if (_selectedStudentId == null || _selectedFeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un élève et un frais')),
      );
      return;
    }

    final students = ref.read(studentProvider);
    final fees = ref.read(feeProvider);
    final student = students.firstWhere((s) => s.id == _selectedStudentId);
    final fee = fees.firstWhere((f) => f.id == _selectedFeeId);

    if (_method == PaymentMethod.mobileMoney) {
      // Naviguer vers écran Mobile Money
      if (!mounted) return;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => MobileMoneyScreen(
            student: student,
            fee: fee,
          ),
        ),
      );
      if (result == true && mounted) Navigator.pop(context);
      return;
    }

    setState(() => _isProcessing = true);

    final payment = await ref.read(paymentProvider.notifier).addPayment(
          studentId: student.id,
          studentName: student.fullName,
          className: student.className,
          feeId: fee.id,
          feeLabel: fee.label,
          montant: fee.montant,
          method: _method,
          chequeNumber:
              _method == PaymentMethod.cheque ? _chequeCtrl.text.trim() : null,
        );

    if (!mounted) return;
    setState(() => _isProcessing = false);
    _showReceiptDialog(payment);
  }

  Future<void> _printAndClose(BuildContext ctx, dynamic payment) async {
    final bytes = await ReceiptPdfService.generate(payment);
    if (!ctx.mounted) return;
    Navigator.pop(ctx);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Recu_${payment.receiptNumber}',
    );
    if (!ctx.mounted) return;
    Navigator.pop(ctx);
  }

  void _showReceiptDialog(dynamic payment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Color(0xFF16A34A)),
          SizedBox(width: 8),
          Text('Paiement enregistré'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reçu N° ${payment.receiptNumber}'),
            Text('Montant : ${payment.montantFormate}'),
            Text('Élève : ${payment.studentName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _printAndClose(context, payment),
            child: const Text('Télécharger reçu PDF'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentProvider);
    final fees = ref.watch(feeProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Enregistrer un paiement'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sélection élève ────────────────────────────────────
            const Text('Élève',
                style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedStudentId,
              hint: const Text('Sélectionner un élève'),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              items: students
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.fullName} — ${s.className}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedStudentId = v),
            ),

            const SizedBox(height: 16),

            // ── Sélection frais ────────────────────────────────────
            const Text('Frais à régler',
                style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedFeeId,
              hint: const Text('Sélectionner un type de frais'),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              items: fees
                  .map((f) => DropdownMenuItem(
                        value: f.id,
                        child: Text(
                            '${f.label} — ${f.montant.toStringAsFixed(0)} FCFA'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFeeId = v),
            ),

            const SizedBox(height: 16),

            // ── Méthode de paiement ────────────────────────────────
            const Text('Méthode de paiement',
                style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            ...PaymentMethod.values.map((m) => _MethodTile(
                  method: m,
                  selected: _method == m,
                  onTap: () => setState(() => _method = m),
                )),

            // ── Numéro chèque si chèque ────────────────────────────
            if (_method == PaymentMethod.cheque) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _chequeCtrl,
                decoration: InputDecoration(
                  labelText: 'Numéro de chèque',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Montant affiché ────────────────────────────────────
            if (_selectedFeeId != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: successGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: successGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Montant à encaisser',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: textDark)),
                    Text(
                      fees
                          .firstWhere((f) => f.id == _selectedFeeId)
                          .montantFormate,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: successGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Bouton valider ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _process,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        _method == PaymentMethod.mobileMoney
                            ? 'Continuer vers Mobile Money'
                            : 'Valider le paiement',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tuile méthode de paiement ──────────────────────────────────────────────
class _MethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon => switch (method) {
        PaymentMethod.especes => Icons.payments_outlined,
        PaymentMethod.mobileMoney => Icons.phone_android,
        PaymentMethod.cheque => Icons.receipt_long_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? primaryBlue.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? primaryBlue : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(_icon, color: selected ? primaryBlue : textGrey, size: 22),
            const SizedBox(width: 12),
            Text(method.label,
                style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? primaryBlue : textDark)),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, color: primaryBlue, size: 18),
          ],
        ),
      ),
    );
  }
}
