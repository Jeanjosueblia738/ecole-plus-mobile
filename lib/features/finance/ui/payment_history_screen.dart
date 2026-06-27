import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/receipt_pdf_service.dart';
import '../data/finance_model.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  String _filter = 'Tous';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(paymentProvider);

    final filtered = _filter == 'Tous'
        ? all
        : all.where((p) => p.status.label == _filter).toList();

    // Du plus récent au plus ancien
    final sorted = [...filtered]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Historique des paiements'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Filtres statut ─────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: ['Tous', 'Validé', 'En attente', 'Échoué'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: selected,
                    selectedColor: primaryBlue.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected ? primaryBlue : textGrey,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),

          // Compteur
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${sorted.length} paiement${sorted.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: textGrey, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Liste ──────────────────────────────────────────────
          Expanded(
            child: sorted.isEmpty
                ? const Center(
                    child: Text('Aucun paiement',
                        style: TextStyle(color: textGrey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      return _PaymentCard(payment: sorted[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends ConsumerWidget {
  final Payment payment;
  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = switch (payment.status) {
      PaymentStatus.valide => successGreen,
      PaymentStatus.enAttente => warningYellow,
      PaymentStatus.echoue => dangerRed,
      PaymentStatus.rembourse => infoBlue,
    };

    final methodIcon = switch (payment.method) {
      PaymentMethod.especes => Icons.payments_outlined,
      PaymentMethod.mobileMoney => Icons.phone_android,
      PaymentMethod.cheque => Icons.receipt_long_outlined,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ligne 1 ──────────────────────────────────────────
          Row(
            children: [
              Icon(methodIcon, color: primaryBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(payment.studentName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(payment.status.label,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Ligne 2 ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(payment.feeLabel,
                    style: const TextStyle(color: textGrey, fontSize: 12)),
              ),
              Text(
                payment.montantFormate,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: successGreen,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Ligne 3 ──────────────────────────────────────────
          Row(
            children: [
              Text(
                '${payment.date.day.toString().padLeft(2, '0')}/${payment.date.month.toString().padLeft(2, '0')}/${payment.date.year}',
                style: const TextStyle(color: textGrey, fontSize: 11),
              ),
              const SizedBox(width: 8),
              Text('• ${payment.receiptNumber}',
                  style: const TextStyle(color: textGrey, fontSize: 11)),
              const Spacer(),
              // Bouton reçu PDF
              GestureDetector(
                onTap: () async {
                  final bytes = await ReceiptPdfService.generate(payment);
                  if (!context.mounted) return;
                  await Printing.layoutPdf(
                    onLayout: (_) async => bytes,
                    name: 'Recu_${payment.receiptNumber}',
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 14, color: primaryBlue),
                    SizedBox(width: 4),
                    Text('Reçu',
                        style: TextStyle(
                            color: primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
