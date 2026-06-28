import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/students_api_service.dart';
import '../../../core/services/attendance_api_service.dart';
import '../../../core/security/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/dashboard_tile.dart';
import 'admin_stats_screen.dart';
import 'admin_validation_screen.dart';
import 'class_management_screen.dart';
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
  int _pendingJustifications = 0;
  int _totalTeachers = 0;
  int _totalClasses = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), _loadRealStats);
  }

  Future<void> _loadRealStats() async {
    if (!mounted) {
      return;
    }
    setState(() => _isLoadingStats = true);
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
          _pendingJustifications =
              (attendanceStats['unJustified'] as num?)?.toInt() ?? 0;
        });
      } catch (e) {
        debugPrint('ECOLE+ absences: $e');
      }
    } catch (e) {
      debugPrint('ECOLE+ stats: $e');
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.role != UserRole.admin) {
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
            // ── KPIs ──────────────────────────────────────────────────
            Row(children: [
              _KpiCard(
                  title: 'Élèves inscrits',
                  value: _totalStudents.toString(),
                  sub: 'Total cette année',
                  icon: Icons.people_alt_outlined,
                  color: primaryBlue,
                  isLoading: _isLoadingStats),
              const SizedBox(width: 12),
              _KpiCard(
                  title: 'Enseignants',
                  value: _totalTeachers.toString(),
                  sub: 'Personnel actif',
                  icon: Icons.school_outlined,
                  color: const Color(0xFF7C3AED),
                  isLoading: _isLoadingStats),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _KpiCard(
                  title: 'Classes',
                  value: _totalClasses.toString(),
                  sub: 'Cette année',
                  icon: Icons.class_outlined,
                  color: const Color(0xFF0D9488),
                  isLoading: _isLoadingStats),
              const SizedBox(width: 12),
              _KpiCard(
                  title: 'Absences',
                  value: _totalAbsences.toString(),
                  sub: 'Toutes classes',
                  icon: Icons.event_busy_outlined,
                  color: dangerRed,
                  isLoading: _isLoadingStats),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _KpiCard(
                  title: 'Justifications',
                  value: _pendingJustifications.toString(),
                  sub: 'À traiter',
                  icon: Icons.access_time_outlined,
                  color: warningYellow,
                  isLoading: _isLoadingStats,
                  showBadge: _pendingJustifications > 0),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ]),

            const SizedBox(height: 24),

            // ── Actions rapides (selon rôle Admin) ────────────────────
            const Text('Actions rapides',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),

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
                label: 'Présences',
                color: dangerRed,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminValidationScreen())),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _ActionBtn(
                label: 'Statistiques',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminStatsScreen())),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: 'Finances',
                color: successGreen,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FinanceDashboardScreen())),
              ),
            ]),

            const SizedBox(height: 24),

            // ── Modules ───────────────────────────────────────────────
            const Text('Modules',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),

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
            DashboardTile(
              icon: Icons.bar_chart_outlined,
              title: 'Statistiques & Rapports',
              color: primaryBlue,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminStatsScreen())),
            ),
            const SizedBox(height: 10),
            DashboardTile(
              icon: Icons.how_to_reg_outlined,
              title: 'Présences & Absences',
              color: dangerRed,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminValidationScreen())),
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

// ── KPI Card ───────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String title, value, sub;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool showBadge;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)))),
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18)),
          ]),
          const SizedBox(height: 12),
          isLoading
              ? Container(
                  height: 24,
                  width: 60,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4)))
              : Row(children: [
                  Flexible(
                      child: Text(value,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color),
                          overflow: TextOverflow.ellipsis)),
                  if (showBadge) ...[
                    const SizedBox(width: 6),
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: dangerRed, shape: BoxShape.circle)),
                  ],
                ]),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ]),
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
