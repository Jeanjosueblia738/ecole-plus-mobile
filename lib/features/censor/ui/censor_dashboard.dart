import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/attendance_api_service.dart';
import '../../../core/services/classes_api_service.dart';
import '../../../core/services/students_api_service.dart';
import '../../../core/utils/school_year.dart';
import '../../admin/ui/admin_validation_screen.dart';
import '../../analytics/ui/dropout_risk_screen.dart';
import '../../cahier/ui/cahier_directeur_screen.dart';
import '../../messaging/ui/messaging_screen.dart';
import '../../settings/ui/settings_screen.dart';
import '../../student/ui/grades_screen.dart';
import '../../student/ui/student_list_screen.dart';
import '../../timetable/ui/timetable_screen.dart';

class CensorDashboard extends ConsumerStatefulWidget {
  const CensorDashboard({super.key});
  @override
  ConsumerState<CensorDashboard> createState() => _CensorDashboardState();
}

class _CensorDashboardState extends ConsumerState<CensorDashboard> {
  int _totalStudents = 0, _totalTeachers = 0, _totalClasses = 0;
  int _totalAbsences = 0, _pendingJustifications = 0;
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
        _totalTeachers = (s['totalTeachers'] as num?)?.toInt() ?? 0;
        _totalClasses = (s['totalClasses'] as num?)?.toInt() ?? 0;
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

  Future<void> _openNotesBulletins() async {
    if (ref.read(studentProvider).isEmpty) {
      await ref.read(studentProvider.notifier).load();
    }
    final students = ref.read(studentProvider);
    if (students.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun élève disponible')),
      );
      return;
    }
    final selected = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Notes & Bulletins'),
        children: students
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, (s.id, s.fullName)),
                  child: Text('${s.fullName} — ${s.className}'),
                ))
            .toList(),
      ),
    );
    if (selected == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GradesScreen(
          studentId: selected.$1,
          studentName: selected.$2,
        ),
      ),
    );
  }

  Future<void> _openTimetable() async {
    List<Map<String, String>> classes = [];
    try {
      final raw = await ClassesApiService.getAll(year: currentSchoolYear());
      classes = raw
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return {
              'id': m['id']?.toString() ?? '',
              'name': m['name']?.toString() ?? '',
            };
          })
          .where((c) => c['id']!.isNotEmpty && c['name']!.isNotEmpty)
          .toList();
    } catch (_) {
      // Fallback : noms issus des élèves chargés
      if (ref.read(studentProvider).isEmpty) {
        await ref.read(studentProvider.notifier).load();
      }
      classes = ref
          .read(classNamesProvider)
          .where((c) => c != 'Toutes')
          .map((name) => {'id': '', 'name': name})
          .toList();
    }
    if (classes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune classe disponible')),
      );
      return;
    }
    if (!mounted) return;
    final selected = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Emploi du temps — classe'),
        children: classes
            .map((c) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, c),
                  child: Text(c['name']!),
                ))
            .toList(),
      ),
    );
    if (selected == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimetableScreen(
          className: selected['name']!,
          classId: selected['id']!.isEmpty ? null : selected['id'],
          canEdit: true,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Suivi pédagogique',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (auth.tenantName != null)
            Text(auth.tenantName!,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: const Color(0xFF4338CA),
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
            _buildProfileCard(
                auth.fullName, 'Censeur', const Color(0xFF4338CA)),
            const SizedBox(height: 20),
            const Text('Suivi pédagogique',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),
            Row(children: [
              _buildKpi('Élèves', _totalStudents.toString(),
                  Icons.people_alt_outlined, primaryBlue),
              const SizedBox(width: 12),
              _buildKpi('Enseignants', _totalTeachers.toString(),
                  Icons.school_outlined, const Color(0xFF7C3AED)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _buildKpi('Classes', _totalClasses.toString(),
                  Icons.class_outlined, const Color(0xFF0D9488)),
              const SizedBox(width: 12),
              _buildKpi('Absences', _totalAbsences.toString(),
                  Icons.event_busy_outlined, dangerRed),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _buildKpi('Justifications', _pendingJustifications.toString(),
                  Icons.pending_outlined, warningYellow),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ]),
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
                    border: Border.all(
                        color: warningYellow.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_outlined,
                        color: warningYellow),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$_pendingJustifications justification(s) à valider',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF92400E)),
                      ),
                    ),
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

            _buildAction(
                Icons.book_outlined,
                'Cahier de texte',
                'Registre pédagogique officiel',
                const Color(0xFF0D9488),
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CahierDirecteurScreen()))),
            const SizedBox(height: 10),
            _buildAction(
                Icons.psychology_outlined,
                'Risque décrochage',
                'IA prédictive — élèves à risque',
                dangerRed,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DropoutRiskScreen()))),
            const SizedBox(height: 10),
            _buildAction(
                Icons.grade_outlined,
                'Notes & Bulletins',
                'Consulter notes et bulletins par élève',
                const Color(0xFF7C3AED),
                _openNotesBulletins),
            const SizedBox(height: 10),
            _buildAction(
                Icons.calendar_month_outlined,
                'Emploi du temps',
                'Consulter et gérer l\'EDT par classe',
                const Color(0xFF4338CA),
                _openTimetable),
            const SizedBox(height: 10),
            _buildAction(
                Icons.check_circle_outlined,
                'Valider justifications',
                'Traiter les absences justifiées',
                successGreen,
                _openJustifications),
            const SizedBox(height: 10),
            _buildAction(
                Icons.people_alt_outlined,
                'Liste des élèves',
                'Consulter les dossiers scolaires',
                primaryBlue,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StudentListScreen()))),
            const SizedBox(height: 10),
            _buildAction(
                Icons.chat_outlined,
                'Messagerie',
                'Communication interne',
                const Color(0xFF1B3A6B),
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MessagingScreen()))),
          ]),
        ),
      ),
    );
  }

  Widget _buildKpi(String label, String value, IconData icon, Color color) =>
      Expanded(
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
                  _loading
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

  Widget _buildAction(IconData icon, String title, String subtitle, Color color,
          VoidCallback onTap) =>
      InkWell(
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

Widget _buildProfileCard(String name, String role, Color color) => Container(
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
