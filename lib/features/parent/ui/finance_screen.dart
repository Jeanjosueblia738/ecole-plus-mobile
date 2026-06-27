import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/receipt_pdf_service.dart';
import '../../finance/data/finance_model.dart';
import '../../finance/ui/mobile_money_screen.dart';

class ParentFinanceScreen extends ConsumerWidget {
  const ParentFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(parentChildProvider);
    if (child == null) {
      return const Scaffold(body: Center(child: Text('Aucun enfant lié')));
    }

    final summary = ref.watch(studentFinanceSummaryProvider(child));
    final fees = ref.watch(feeProvider);

    final soldeColor = summary.estAJour ? successGreen : dangerRed;

    String xof(double v) =>
        '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Suivi des paiements'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Résumé solde ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: soldeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: soldeColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    summary.estAJour
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: soldeColor,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.estAJour ? 'Situation à jour' : 'Solde restant dû',
                    style: TextStyle(color: soldeColor, fontSize: 13),
                  ),
                  Text(
                    xof(summary.solde.abs()),
                    style: TextStyle(
                        color: soldeColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _FinStat('Total dû', xof(summary.totalDu), textGrey),
                      _FinStat('Payé', xof(summary.totalPaye), successGreen),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text('Frais à régler',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 10),

            // ── Liste frais avec bouton payer ──────────────────────
            ...fees.map((fee) {
              final paid = summary.payments
                  .where((p) =>
                      p.feeId == fee.id && p.status == PaymentStatus.valide)
                  .fold(0.0, (s, p) => s + p.montant);
              final isPaid = paid >= fee.montant;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPaid
                        ? successGreen.withValues(alpha: 0.3)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPaid
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isPaid ? successGreen : textGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fee.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(xof(fee.montant),
                              style: const TextStyle(
                                  color: textGrey, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (!isPaid)
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MobileMoneyScreen(
                              student: child,
                              fee: fee,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Payer',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      )
                    else
                      const Text('Réglé',
                          style: TextStyle(
                              color: successGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                  ],
                ),
              );
            }),

            if (summary.payments.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Historique',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark)),
              const SizedBox(height: 10),
              ...summary.payments.reversed
                  .map((p) => _PaymentHistoryTile(payment: p)),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FinStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        Text(label, style: const TextStyle(color: textGrey, fontSize: 11)),
      ],
    );
  }
}

class _PaymentHistoryTile extends StatelessWidget {
  final Payment payment;
  const _PaymentHistoryTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (payment.status) {
      PaymentStatus.valide => successGreen,
      PaymentStatus.enAttente => warningYellow,
      _ => dangerRed,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.feeLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '${payment.date.day.toString().padLeft(2, '0')}/${payment.date.month.toString().padLeft(2, '0')}/${payment.date.year} • ${payment.method.label}',
                  style: const TextStyle(color: textGrey, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(payment.montantFormate,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              Text(payment.status.label,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final bytes = await ReceiptPdfService.generate(payment);
              if (!context.mounted) return;
              await Printing.layoutPdf(
                onLayout: (_) async => bytes,
                name: 'Recu_${payment.receiptNumber}',
              );
            },
            child:
                const Icon(Icons.picture_as_pdf, color: primaryBlue, size: 18),
          ),
        ],
      ),
    );
  }
}
