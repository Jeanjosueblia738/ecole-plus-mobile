import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/students_api_service.dart';
import '../../../core/services/attendance_api_service.dart';
import '../../admin/ui/admin_validation_screen.dart';
import '../../settings/ui/settings_screen.dart';
import '../../student/ui/student_list_screen.dart';
import '../../teacher/ui/attendance_input_screen.dart';

class SurveillantDashboard extends ConsumerStatefulWidget {
  const SurveillantDashboard({super.key});
  @override
  ConsumerState<SurveillantDashboard> createState() =>
      _SurveillantDashboardState();
}

class _SurveillantDashboardState extends ConsumerState<SurveillantDashboard> {
  int _totalStudents = 0, _totalAbsences = 0, _pendingJustifications = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        StudentsApiService.getStats()
            .catchError((_) async => <String, dynamic>{}),
        AttendanceApiService.getStats()
            .catchError((_) async => <String, dynamic>{}),
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
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
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
            _ProfileCard(
                name: auth.fullName, role: 'Surveillant Général', color: color),
            const SizedBox(height: 20),
            const Text('Discipline & Présences',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),
            Row(children: [
              _KpiCard(
                  label: 'Élèves',
                  value: _totalStudents.toString(),
                  icon: Icons.people_alt_outlined,
                  color: primaryBlue,
                  loading: _loading),
              const SizedBox(width: 12),
              _KpiCard(
                  label: 'Absences',
                  value: _totalAbsences.toString(),
                  icon: Icons.event_busy_outlined,
                  color: dangerRed,
                  loading: _loading),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _KpiCard(
                  label: 'À justifier',
                  value: _pendingJustifications.toString(),
                  icon: Icons.pending_outlined,
                  color: warningYellow,
                  loading: _loading),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ]),
            if (_pendingJustifications > 0) ...[
              const SizedBox(height: 16),
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
            const Text('Actions rapides',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),
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
