import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/students_api_service.dart';
import '../../../core/services/attendance_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/dashboard_tile.dart';
import '../../../shared/widgets/workspace_hero.dart';
import 'admin_stats_screen.dart';
// AdminValidationScreen masqué : API sans endpoint validate pending (voir commentaire écran).
import 'class_management_screen.dart';
import '../../analytics/ui/dropout_risk_screen.dart';
import '../../student/ui/student_list_screen.dart';
import '../../finance/ui/finance_dashboard_screen.dart';
import '../../settings/ui/settings_screen.dart';
import '../../users/ui/users_screen.dart';
import '../../messaging/ui/messaging_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});
  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _totalStudents = 0;
  int _totalAbsences = 0;
  int _totalTeachers = 0;
  int _totalClasses = 0;
  bool _isLoadingStats = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), _loadRealStats);
  }

  Future<void> _loadRealStats() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoadingStats = true;
      _error = null;
    });
    try {
      final studentStats = await StudentsApiService.getStats()
          .timeout(const Duration(seconds: 15));
      if (!mounted) {
        return;
      }
      setState(() {
        _totalStudents = (studentStats['total'] as num?)?.toInt() ?? 0;
        _totalTeachers = (studentStats['totalTeachers'] as num?)?.toInt() ?? 0;
        _totalClasses = (studentStats['totalClasses'] as num?)?.toInt() ?? 0;
        _isLoadingStats = false;
      });
      try {
        final attendanceStats = await AttendanceApiService.getStats()
            .timeout(const Duration(seconds: 15));
        if (!mounted) {
          return;
        }
        setState(() {
          _totalAbsences =
              (attendanceStats['totalAbsences'] as num?)?.toInt() ?? 0;
        });
      } catch (_) {
        if (mounted) {
          setState(() => _error =
              'Impossible de charger toutes les statistiques. Tirez pour actualiser.');
        }
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingStats = false;
        _error =
            'Impossible de charger les statistiques. Vérifiez votre connexion.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (!auth.isDirection) {
      return const Scaffold(body: Center(child: Text('Accès refusé')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tableau de bord',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (auth.tenantName != null)
            Text(auth.tenantName!,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoadingStats)
            const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))),
          IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 20),
              onPressed: _loadRealStats),
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
        onRefresh: _loadRealStats,
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
                        onPressed: _loadRealStats,
                        child: const Text('Réessayer')),
                  ],
                ),
              ),
            // ── Vue d'ensemble ────────────────────────────────────────
            WorkspaceHero(
              eyebrow: 'Direction',
              title: 'Vue d\'ensemble',
              subtitle: 'Effectifs, scolarité et pilotage de l\'établissement',
              color: primaryBlue,
              loading: _isLoadingStats,
              metrics: [
                WorkspaceHeroMetric(
                    label: 'Élèves', value: _totalStudents.toString()),
                WorkspaceHeroMetric(
                    label: 'Enseignants', value: _totalTeachers.toString()),
                WorkspaceHeroMetric(
                    label: 'Classes', value: _totalClasses.toString()),
                WorkspaceHeroMetric(
                    label: 'Absences', value: _totalAbsences.toString()),
              ],
            ),

            const SizedBox(height: 24),

            // ── Actions ───────────────────────────────────────────────
            const WorkspaceSectionTitle('Actions principales'),

            Row(children: [
              _ActionBtn(
                label: 'Liste des élèves',
                color: primaryBlue,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StudentListScreen())),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: 'Statistiques',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminStatsScreen())),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _ActionBtn(
                label: 'Finances',
                color: successGreen,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FinanceDashboardScreen())),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: 'Messagerie',
                color: const Color(0xFF1B3A6B),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MessagingScreen())),
              ),
            ]),

            const SizedBox(height: 24),

            // ── Modules ───────────────────────────────────────────────
            const WorkspaceSectionTitle('Modules'),

            if (auth.isOwner) ...[
              DashboardTile(
                icon: Icons.manage_accounts_outlined,
                title: 'Gestion des utilisateurs',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const UsersScreen())),
              ),
              const SizedBox(height: 10),
              DashboardTile(
                icon: Icons.class_outlined,
                title: 'Gestion des classes',
                color: const Color(0xFF0D9488),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ClassManagementScreen())),
              ),
              const SizedBox(height: 10),
            ],
            DashboardTile(
              icon: Icons.bar_chart_outlined,
              title: 'Statistiques & Rapports',
              color: primaryBlue,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminStatsScreen())),
            ),
            const SizedBox(height: 10),
            DashboardTile(
              icon: Icons.psychology_outlined,
              title: 'Risque décrochage',
              color: dangerRed,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DropoutRiskScreen())),
            ),
            const SizedBox(height: 10),
            DashboardTile(
              icon: Icons.attach_money_outlined,
              title: 'Finance',
              color: successGreen,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FinanceDashboardScreen())),
            ),
            const SizedBox(height: 10),
            DashboardTile(
              icon: Icons.chat_outlined,
              title: 'Messagerie',
              color: const Color(0xFF1B3A6B),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MessagingScreen())),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Action Button ──────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(12)),
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
      ),
    );
  }
}
