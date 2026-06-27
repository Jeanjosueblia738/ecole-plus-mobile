import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'payment_screen.dart';
import 'payment_history_screen.dart';
import 'fee_management_screen.dart';

class FinanceDashboardScreen extends ConsumerWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(financeStatsProvider);
    final students = ref.watch(studentProvider);
    final payments = ref.watch(paymentProvider);
    final pending = ref.watch(pendingPaymentsProvider);

    final encaisse = stats['encaisse'] ?? 0;
    final taux = ((stats['tauxRecouvrement'] ?? 0) * 100);

    // Formatter XOF
    String xof(double v) =>
        '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Gestion Financière'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Carte récapitulatif ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total encaissé',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(xof(encaisse),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Taux de recouvrement',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 11)),
                          Text('${taux.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('En attente validation',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 11)),
                          Text(
                              '${pending.length} paiement${pending.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  // Barre taux recouvrement
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (taux / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── KPIs ──────────────────────────────────────────────
            Row(children: [
              _KpiCard(
                label: 'Élèves',
                value: students.length.toString(),
                icon: Icons.people_outline,
                color: primaryBlue,
              ),
              const SizedBox(width: 10),
              _KpiCard(
                label: 'Paiements',
                value: payments.length.toString(),
                icon: Icons.receipt_outlined,
                color: successGreen,
              ),
              const SizedBox(width: 10),
              _KpiCard(
                label: 'En attente',
                value: pending.length.toString(),
                icon: Icons.pending_outlined,
                color: pending.isEmpty ? textGrey : warningYellow,
                showAlert: pending.isNotEmpty,
              ),
            ]),

            const SizedBox(height: 20),
            const Text('Actions',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),

            // ── Actions ────────────────────────────────────────────
            _ActionTile(
              icon: Icons.add_card,
              title: 'Enregistrer un paiement',
              subtitle: 'Espèces, Mobile Money ou Chèque',
              color: successGreen,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PaymentScreen())),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.history,
              title: 'Historique des paiements',
              subtitle:
                  '${payments.length} paiement${payments.length > 1 ? 's' : ''} enregistré${payments.length > 1 ? 's' : ''}',
              color: infoBlue,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PaymentHistoryScreen())),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.settings,
              title: 'Configurer les frais',
              subtitle: 'Scolarité, transport, examens...',
              color: primaryBlue,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FeeManagementScreen())),
            ),

            if (pending.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Mobile Money en attente',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: warningYellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${pending.length}',
                        style: const TextStyle(
                            color: warningYellow, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...pending.map((p) => _PendingPaymentCard(payment: p)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── KPI card ───────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool showAlert;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.showAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 22),
                if (showAlert)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: dangerRed, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: textGrey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Action tile ────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(color: textGrey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Carte paiement en attente ──────────────────────────────────────────────
class _PendingPaymentCard extends ConsumerWidget {
  final dynamic payment;
  const _PendingPaymentCard({required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningYellow.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_android, color: warningYellow, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    '${payment.operatorName ?? 'Mobile Money'} • ${payment.montantFormate}',
                    style: const TextStyle(color: textGrey, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(paymentProvider.notifier)
                  .validatePayment(payment.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paiement validé ✓'),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: successGreen,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Valider',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
