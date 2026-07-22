import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/teacher_api_service.dart';
import '../../../core/utils/teacher_class_utils.dart';
import '../../settings/ui/settings_screen.dart';
import '../../grades/ui/grade_input_screen.dart';
import 'attendance_input_screen.dart';
import 'teacher_my_classes_screen.dart';
import 'teacher_stats_screen.dart';
import '../../cahier/ui/cahier_screen.dart';
import '../../exams/ui/exams_screen.dart';
import '../../messaging/ui/messaging_screen.dart';
import '../../../shared/widgets/workspace_hero.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});
  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  List<dynamic> _classes = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), _loadData);
  }

  Future<void> _loadData() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var partialFailure = false;
      final results = await Future.wait([
        TeacherApiService.getMyClasses().catchError((_) {
          partialFailure = true;
          return <dynamic>[];
        }),
        TeacherApiService.getStats().catchError((_) {
          partialFailure = true;
          return <String, dynamic>{};
        }),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _classes = results[0] as List<dynamic>;
        _stats = results[1] as Map<String, dynamic>?;
        _loading = false;
        if (partialFailure) {
          _error =
              'Impossible de charger toutes les données. Tirez pour actualiser.';
        }
      });
    } catch (e) {
      debugPrint('ECOLE+ teacher: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Impossible de charger les données. Vérifiez votre connexion.';
        });
      }
    }
  }

  Future<Map<String, String>?> _pickClass() async {
    if (_classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucune classe assignée'),
      ));
      return null;
    }
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choisir une classe'),
        children: _classes.map((c) {
          final id = c['id']?.toString() ?? '';
          final name = c['name']?.toString() ?? 'Classe';
          final subject = firstClassSubject(c) ?? '';
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, {
              'id': id,
              'name': name,
              'subject': subject,
            }),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name),
                if (classSubjects(c).isNotEmpty)
                  Text(
                    classSubjects(c).join(', '),
                    style: const TextStyle(fontSize: 11, color: textGrey),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openAttendance() async {
    final picked = await _pickClass();
    if (picked == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceInputScreen(
          classId: picked['id'],
          className: picked['name'] ?? '',
          subject: picked['subject'] ?? '',
          duration: '55',
        ),
      ),
    );
  }

  Future<void> _openGrades() async {
    final picked = await _pickClass();
    if (picked == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GradeInputScreen(
          classId: picked['id'],
          className: picked['name'] ?? '',
          trimestre: 'T1',
          initialSubject: picked['subject']?.isNotEmpty == true
              ? picked['subject']
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.role != UserRole.teacher) {
      return const Scaffold(body: Center(child: Text('Accès refusé')));
    }

    final today =
        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now());
    final fullName = '${auth.firstName ?? ''} ${auth.lastName ?? ''}'.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Espace Enseignant',
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
              onPressed: _loadData),
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
        onRefresh: _loadData,
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
                        onPressed: _loadData, child: const Text('Réessayer')),
                  ],
                ),
              ),
            WorkspaceHero(
              eyebrow: 'Enseignant',
              title: fullName.isNotEmpty ? fullName : 'Espace pédagogique',
              subtitle:
                  '$today · ${_classes.length} classe(s) assignée(s)',
              color: const Color(0xFF7C3AED),
              loading: _loading,
              metrics: [
                WorkspaceHeroMetric(
                    label: 'Mes classes', value: _classes.length.toString()),
                WorkspaceHeroMetric(
                    label: 'Élèves',
                    value: (_stats?['totalStudents'] ?? 0).toString()),
                WorkspaceHeroMetric(
                    label: 'Notes',
                    value: (_stats?['totalGrades'] ?? 0).toString()),
                WorkspaceHeroMetric(
                    label: 'Absences',
                    value: (_stats?['totalAbsences'] ?? 0).toString()),
              ],
            ),

            const SizedBox(height: 20),

            const WorkspaceSectionTitle('Actions pédagogiques'),
            Row(children: [
              _ActionBtn(
                  icon: Icons.how_to_reg_outlined,
                  label: 'Faire\nl\'appel',
                  color: primaryBlue,
                  onTap: _openAttendance),
              const SizedBox(width: 12),
              _ActionBtn(
                  icon: Icons.grade_outlined,
                  label: 'Saisir\nles notes',
                  color: const Color(0xFF7C3AED),
                  onTap: _openGrades),
              const SizedBox(width: 12),
              _ActionBtn(
                  icon: Icons.bar_chart_outlined,
                  label: 'Mes\nstatistiques',
                  color: successGreen,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TeacherStatsScreen()))),
            ]),

            const SizedBox(height: 20),

            // ── Mes classes ────────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Mes classes',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark)),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TeacherMyClassesScreen())),
                child: const Text('Voir tout'),
              ),
            ]),
            const SizedBox(height: 10),
            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator()))
            else if (_classes.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Icon(Icons.class_outlined, color: textGrey),
                  SizedBox(width: 12),
                  Text('Aucune classe assignée',
                      style: TextStyle(color: textGrey)),
                ]),
              )
            else
              ..._classes.take(4).map((cls) => _ClassCard(
                    classData: cls,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TeacherMyClassesScreen())),
                  )),

            const SizedBox(height: 20),

            // ── Modules ────────────────────────────────────────────────
            const Text('Modules',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),
            _ModuleTile(
                icon: Icons.book_outlined,
                title: 'Cahier de texte',
                subtitle: 'Registre pédagogique officiel',
                color: const Color(0xFF0D9488),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CahierScreen()))),
            const SizedBox(height: 10),
            _ModuleTile(
                icon: Icons.class_outlined,
                title: 'Mes classes',
                subtitle: '${_classes.length} classe(s) assignée(s)',
                color: primaryBlue,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TeacherMyClassesScreen()))),
            const SizedBox(height: 10),
            _ModuleTile(
                icon: Icons.how_to_reg_outlined,
                title: 'Appel & Présences',
                subtitle: 'Enregistrer les présences quotidiennes',
                color: successGreen,
                onTap: _openAttendance),
            const SizedBox(height: 10),
            _ModuleTile(
                icon: Icons.grade_outlined,
                title: 'Saisie des notes',
                subtitle: 'Notes : devoirs, interrogations, examens',
                color: const Color(0xFF7C3AED),
                onTap: _openGrades),
            const SizedBox(height: 10),
            _ModuleTile(
                icon: Icons.bar_chart_outlined,
                title: 'Statistiques',
                subtitle: 'Performances et analyses de mes classes',
                color: infoBlue,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TeacherStatsScreen()))),
            const SizedBox(height: 10),
            _ModuleTile(
                icon: Icons.event_note_outlined,
                title: 'Évaluations',
                subtitle: 'Agenda des interrogations et examens',
                color: dangerRed,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ExamsScreen.forTeacher()))),
            const SizedBox(height: 10),
            _ModuleTile(
                icon: Icons.chat_outlined,
                title: 'Messagerie',
                subtitle: 'Communication interne',
                color: const Color(0xFF1B3A6B),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MessagingScreen()))),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isLoading;
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                isLoading
                    ? LinearProgressIndicator(
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.1))
                    : Text(value,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color)),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: textGrey)),
              ])),
        ]),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 22)),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final dynamic classData;
  final VoidCallback onTap;
  const _ClassCard({required this.classData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100)),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.class_outlined,
                  color: primaryBlue, size: 22)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(classData['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(classData['level'] ?? '',
                    style: const TextStyle(fontSize: 12, color: textGrey)),
              ])),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ]),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ModuleTile(
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
          Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }
}
