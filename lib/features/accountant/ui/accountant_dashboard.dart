import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/students_api_service.dart';
import '../../finance/ui/finance_dashboard_screen.dart';
import '../../finance/ui/payment_history_screen.dart';
import '../../finance/ui/payment_screen.dart';
import '../../finance/ui/unpaid_students_screen.dart';
import '../../settings/ui/settings_screen.dart';

class AccountantDashboard extends ConsumerStatefulWidget {
  const AccountantDashboard({super.key});
  @override
  ConsumerState<AccountantDashboard> createState() =>
      _AccountantDashboardState();
}

class _AccountantDashboardState extends ConsumerState<AccountantDashboard> {
  int _unpaidCount = 0;
  double _totalDu = 0, _totalPaye = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await StudentsApiService.getStats();
      if (!mounted) {
        return;
      }
      setState(() {
        _unpaidCount = (s['unpaidCount'] as num?)?.toInt() ?? 0;
        _totalDu = (s['totalDu'] as num?)?.toDouble() ?? 0;
        _totalPaye = (s['totalPaye'] as num?)?.toDouble() ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Impossible de charger les statistiques. Vérifiez votre connexion.';
        });
      }
    }
  }

  String _fmt(double n) {
    final val = n.toInt();
    return '${val.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final solde = _totalDu - _totalPaye;
    final taux = _totalDu > 0 ? (_totalPaye / _totalDu * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Finance',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (auth.tenantName != null)
            Text(auth.tenantName!,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: successGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))),
          IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 20),
              onPressed: _loadStats),
          IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: () => ref.read(authProvider.notifier).logout()),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              color: Colors.red.shade800, fontSize: 13)),
                    ),
                    TextButton(
                        onPressed: _loadStats, child: const Text('Réessayer')),
                  ],
                ),
              ),
            _ProfileCard(
                name: auth.fullName,
                role: 'Comptable / Caissier',
                color: successGreen),
            const SizedBox(height: 20),
            const Text('Situation financière',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),

            // Taux recouvrement
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: taux >= 80
                    ? successGreen.withValues(alpha: 0.08)
                    : warningYellow.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: taux >= 80
                        ? successGreen.withValues(alpha: 0.3)
                        : warningYellow.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(Icons.trending_up_outlined,
                    color: taux >= 80 ? successGreen : warningYellow, size: 32),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$taux%',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: taux >= 80 ? successGreen : warningYellow)),
                  const Text('Taux de recouvrement',
                      style: TextStyle(fontSize: 12, color: textGrey)),
                ]),
              ]),
            ),

            const SizedBox(height: 12),
            Row(children: [
              _KpiCard(
                  label: 'Total dû',
                  value: _fmt(_totalDu),
                  icon: Icons.account_balance_outlined,
                  color: primaryBlue,
                  loading: _loading),
              const SizedBox(width: 12),
              _KpiCard(
                  label: 'Encaissé',
                  value: _fmt(_totalPaye),
                  icon: Icons.payments_outlined,
                  color: successGreen,
                  loading: _loading),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _KpiCard(
                  label: 'Reste',
                  value: _fmt(solde),
                  icon: Icons.money_off_outlined,
                  color: dangerRed,
                  loading: _loading),
              const SizedBox(width: 12),
              _KpiCard(
                  label: 'Impayés',
                  value: _unpaidCount.toString(),
                  icon: Icons.people_alt_outlined,
                  color: warningYellow,
                  loading: _loading),
            ]),

            const SizedBox(height: 20),
            const Text('Actions rapides',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),
            _ActionTile(
                icon: Icons.add_card_outlined,
                title: 'Enregistrer un paiement',
                subtitle: 'Encaisser des frais de scolarité',
                color: successGreen,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PaymentScreen()))),
            const SizedBox(height: 10),
            _ActionTile(
                icon: Icons.receipt_long_outlined,
                title: 'Historique des paiements',
                subtitle: 'Voir tous les paiements',
                color: primaryBlue,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PaymentHistoryScreen()))),
            const SizedBox(height: 10),
            _ActionTile(
                icon: Icons.warning_amber_outlined,
                title: 'Liste des impayés',
                subtitle: '$_unpaidCount élève(s) non à jour',
                color: dangerRed,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UnpaidStudentsScreen()))),
            const SizedBox(height: 10),
            _ActionTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Espace finance',
                subtitle: 'Frais, Mobile Money, synthèse',
                color: const Color(0xFF0D9488),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FinanceDashboardScreen()))),
          ]),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name, role;
  final Color color;
  const _ProfileCard(
      {required this.name, required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold))),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(role,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool loading;
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                loading
                    ? LinearProgressIndicator(
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.1))
                    : Text(value,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color),
                        overflow: TextOverflow.ellipsis),
                Text(label,
                    style: const TextStyle(fontSize: 10, color: textGrey)),
              ])),
        ]),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

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
            border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22)),
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
              ])),
          Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }
}
