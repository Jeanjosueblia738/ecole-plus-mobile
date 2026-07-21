import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/students_api_service.dart';
import '../../../core/services/attendance_api_service.dart';
import '../../admin/ui/admin_validation_screen.dart';
import '../../analytics/ui/dropout_risk_screen.dart';
import '../../settings/ui/settings_screen.dart';
import '../../student/ui/student_list_screen.dart';
import '../../teacher/ui/attendance_input_screen.dart';
import '../../../shared/widgets/workspace_hero.dart';

class SurveillantDashboard extends ConsumerStatefulWidget {
  const SurveillantDashboard({super.key});
  @override
  ConsumerState<SurveillantDashboard> createState() =>
      _SurveillantDashboardState();
}

class _SurveillantDashboardState extends ConsumerState<SurveillantDashboard> {
  int _totalStudents = 0, _totalAbsences = 0, _pendingJustifications = 0;
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
      var partialFailure = false;
      final results = await Future.wait([
        StudentsApiService.getStats().catchError((_) async {
          partialFailure = true;
          return <String, dynamic>{};
        }),
        AttendanceApiService.getStats().catchError((_) async {
          partialFailure = true;
          return <String, dynamic>{};
        }),
      ]);
      if (!mounted) {
        return;
      }
      final s = results[0];
      final a = results[1];
      setState(() {
        _totalStudents = (s['total'] as num?)?.toInt() ?? 0;
        _totalAbsences = (a['totalAbsences'] as num?)?.toInt() ?? 0;
        _pendingJustifications = (a['unJustified'] as num?)?.toInt() ?? 0;
        _loading = false;
        if (partialFailure) {
          _error =
              'Impossible de charger toutes les statistiques. Tirez pour actualiser.';
        }
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

  Future<void> _openAppel() async {
    final classes = ref
        .read(classNamesProvider)
        .where((c) => c != 'Toutes')
        .toList();
    String className = '';
    if (classes.isNotEmpty) {
      final selected = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Choisir une classe'),
          children: classes
              .map((c) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, c),
                    child: Text(c),
                  ))
              .toList(),
        ),
      );
      if (selected == null) return;
      className = selected;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceInputScreen(
          className: className,
          subject: 'Appel',
          duration: '55',
        ),
      ),
    );
  }

  void _openJustifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminValidationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    const color = Color(0xFFEA580C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Vie scolaire',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (auth.tenantName != null)
            Text(auth.tenantName!,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: color,
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
            WorkspaceHero(
              eyebrow: 'Vie scolaire',
              title: 'Discipline & présences',
              subtitle: 'Appel, justifications et suivi des élèves',
              color: color,
              loading: _loading,
              metrics: [
                WorkspaceHeroMetric(
                    label: 'Élèves', value: _totalStudents.toString()),
                WorkspaceHeroMetric(
                    label: 'Absences', value: _totalAbsences.toString()),
                WorkspaceHeroMetric(
                    label: 'À justifier',
                    value: _pendingJustifications.toString()),
              ],
            ),
            if (_pendingJustifications > 0) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _openJustifications,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: warningYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: warningYellow.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_outlined,
                        color: warningYellow),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            '$_pendingJustifications justification(s) en attente de validation',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF92400E)))),
                    Icon(Icons.chevron_right,
                        color: warningYellow.withValues(alpha: 0.7)),
                  ]),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const WorkspaceSectionTitle('Actions principales'),
            _ActionTile(
                icon: Icons.how_to_reg_outlined,
                title: 'Faire l\'appel',
                subtitle: 'Enregistrer les présences',
                color: color,
                onTap: _openAppel),
            const SizedBox(height: 10),
            _ActionTile(
                icon: Icons.check_circle_outlined,
                title: 'Valider justifications',
                subtitle: 'Traiter les absences justifiées',
                color: successGreen,
                onTap: _openJustifications),
            const SizedBox(height: 10),
            _ActionTile(
                icon: Icons.psychology_outlined,
                title: 'Risque décrochage',
                subtitle: 'IA prédictive — élèves à risque',
                color: dangerRed,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DropoutRiskScreen()))),
            const SizedBox(height: 10),
            _ActionTile(
                icon: Icons.people_alt_outlined,
                title: 'Liste des élèves',
                subtitle: 'Consulter les dossiers',
                color: primaryBlue,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StudentListScreen()))),
          ]),
        ),
      ),
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
