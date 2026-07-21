import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/services/finance_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/school_year.dart';
import '../../../shared/widgets/workspace_hero.dart';
import 'payment_screen.dart';
import 'payment_history_screen.dart';
import 'fee_management_screen.dart';

class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() =>
      _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState
    extends ConsumerState<FinanceDashboardScreen> {
  bool _loading = true;
  String? _error;
  double? _apiEncaisse;
  double? _apiTaux;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final year = currentSchoolYear();
      await Future.wait([
        ref.read(studentProvider.notifier).load(),
        ref.read(feeProvider.notifier).load(year: year),
        ref.read(paymentProvider.notifier).loadAll(year: year),
      ]);
      try {
        final stats = await FinanceApiService.getStats(year: year);
        final encaisse = (stats['totalRecouvertXof'] as num?)?.toDouble() ??
            (stats['totalPaye'] as num?)?.toDouble() ??
            (stats['encaissementsAujourdhuiXof'] as num?)?.toDouble();
        final tauxRaw = stats['tauxRecouvrement'];
        double? taux;
        if (tauxRaw is num) {
          taux = tauxRaw <= 1 ? tauxRaw * 100 : tauxRaw.toDouble();
        } else if (tauxRaw is String) {
          taux = double.tryParse(tauxRaw.replaceAll('%', ''));
        }
        _apiEncaisse = encaisse;
        _apiTaux = taux;
      } catch (_) {
        // fallback local stats below
      }
      final feeErr = ref.read(feeProvider.notifier).error;
      final payErr = ref.read(paymentProvider.notifier).error;
      if (feeErr != null || payErr != null) {
        _error = [feeErr, payErr].whereType<String>().join(' · ');
      }
    } catch (e) {
      _error = 'Impossible de charger la finance';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isAccountant = auth.role == UserRole.accountant;
    final isCashier = auth.role == UserRole.cashier;
    final canCash = isAccountant || isCashier;
    final canConfigureFees = isAccountant;
    final isViewOnly = !canCash;
    final stats = ref.watch(financeStatsProvider);
    final payments = ref.watch(paymentProvider);
    final pending = ref.watch(pendingPaymentsProvider);

    final encaisse = _apiEncaisse ?? stats['encaisse'] ?? 0;
    final taux = _apiTaux ?? ((stats['tauxRecouvrement'] ?? 0) * 100);

    // Formatter XOF
    String xof(double v) =>
        '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(isViewOnly ? 'Vue financière' : 'Gestion Financière'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: warningYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!, style: const TextStyle(fontSize: 13)),
              ),
            ],
            WorkspaceHero(
              eyebrow: isViewOnly
                  ? 'Direction'
                  : (canConfigureFees ? 'Comptabilité' : 'Poste de caisse'),
              title: isViewOnly ? 'Vue globale' : 'Gestion financière',
              subtitle: isViewOnly
                  ? 'Synthèse du recouvrement — lecture seule'
                  : 'Encaissements, historique et suivi du recouvrement',
              color: primaryBlue,
              loading: _loading,
              metrics: [
                WorkspaceHeroMetric(label: 'Encaissé', value: xof(encaisse)),
                WorkspaceHeroMetric(
                    label: 'Taux', value: '${taux.toStringAsFixed(1)}%'),
                WorkspaceHeroMetric(
                    label: 'En attente', value: '${pending.length}'),
                WorkspaceHeroMetric(
                    label: 'Paiements', value: '${payments.length}'),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (taux / 100).clamp(0.0, 1.0),
                backgroundColor: primaryBlue.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 20),
            WorkspaceSectionTitle(isViewOnly ? 'Consultation' : 'Actions'),
            const SizedBox(height: 12),

            if (canCash) ...[
              _ActionTile(
                icon: Icons.add_card,
                title: 'Enregistrer un paiement',
                subtitle: 'Espèces, Mobile Money ou Chèque',
                color: successGreen,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PaymentScreen())),
              ),
              const SizedBox(height: 10),
            ],
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
            if (canConfigureFees) ...[
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
            ],
            if (isViewOnly) ...[
              const SizedBox(height: 16),
              Text(
                'Le pilotage financier et les encaissements sont réservés au comptable et au caissier.',
                style: TextStyle(fontSize: 12, color: textGrey),
              ),
            ],

            if (canCash && pending.isNotEmpty) ...[
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
              final ok = await ref
                  .read(paymentProvider.notifier)
                  .validatePayment(payment.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Paiement validé ✓'
                      : 'Validation serveur non disponible'),
                  backgroundColor:
                      ok ? const Color(0xFF16A34A) : const Color(0xFFB45309),
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
