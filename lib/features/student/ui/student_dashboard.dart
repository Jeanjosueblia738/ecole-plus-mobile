import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/student_api_service.dart';
import '../../settings/ui/settings_screen.dart';
import 'grades_screen.dart';
import 'attendance_history_screen.dart';

Color _subjectColor(String s) => switch (s) {
      'Mathématiques' => const Color(0xFF1E3A8A),
      'Français' => const Color(0xFF7C3AED),
      'Anglais' => const Color(0xFF059669),
      'SVT' => const Color(0xFF16A34A),
      'Physique-Chimie' => const Color(0xFFDC2626),
      'Histoire-Géographie' => const Color(0xFFF59E0B),
      'Philosophie' => const Color(0xFF0891B2),
      'EPS' => const Color(0xFFEA580C),
      'Arts' => const Color(0xFFDB2777),
      _ => const Color(0xFF6B7280),
    };

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  List<dynamic> _grades = [];
  Map<String, dynamic>? _attendance;
  bool _loading = true;
  String _trimestre = 'T1';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), _loadData);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        StudentApiService.getMyGrades(trimestre: _trimestre)
            .catchError((_) => <dynamic>[]),
        StudentApiService.getMyAttendance()
            .catchError((_) => <String, dynamic>{}),
      ]);
      if (!mounted) return;
      setState(() {
        _grades = results[0] as List<dynamic>;
        _attendance = results[1] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      debugPrint('ECOLE+ student: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  double? get _moyenne {
    if (_grades.isEmpty) return null;
    double total = 0;
    int coefTotal = 0;
    for (final g in _grades) {
      final val = (g['value'] as num).toDouble();
      final coef = (g['coefficient'] as num?)?.toInt() ?? 1;
      total += val * coef;
      coefTotal += coef;
    }
    return coefTotal > 0 ? total / coefTotal : null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.role != UserRole.student) {
      return const Scaffold(body: Center(child: Text('Accès refusé')));
    }

    final today = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    final totalAbsences = (_attendance?['stats']?['absences'] ?? 0) as int;
    final nonJustified = (_attendance?['stats']?['nonJustified'] ?? 0) as int;
    final moyenne = _moyenne;
    final firstName = auth.firstName ?? '';
    final lastName = auth.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    final className = auth.className ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mon espace',
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
            // Carte profil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'E',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(fullName.isNotEmpty ? fullName : 'Élève',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      if (className.isNotEmpty)
                        Text(className,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(today,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12)),
                    ])),
                if (moyenne != null)
                  Column(children: [
                    Text(moyenne.toStringAsFixed(1),
                        style: TextStyle(
                          color: moyenne >= 10
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFCA5A5),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        )),
                    const Text('/20',
                        style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ]),
              ]),
            ),

            const SizedBox(height: 16),

            // Sélecteur trimestre
            Row(children: [
              const Text('Trimestre :',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              ...['T1', 'T2', 'T3'].map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _trimestre = t);
                        _loadData();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _trimestre == t ? primaryBlue : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _trimestre == t
                                  ? primaryBlue
                                  : Colors.grey.shade200),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    _trimestre == t ? Colors.white : textGrey)),
                      ),
                    ),
                  )),
            ]),

            const SizedBox(height: 16),

            // KPIs
            Row(children: [
              _KpiCard(
                label: 'Absences',
                icon: Icons.event_busy_outlined,
                value: totalAbsences.toString(),
                subLabel:
                    '$nonJustified non justifiée${nonJustified > 1 ? "s" : ""}',
                color: nonJustified > 0 ? dangerRed : successGreen,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const AttendanceHistoryScreen(history: []))),
              ),
              const SizedBox(width: 12),
              _KpiCard(
                label: 'Notes saisies',
                icon: Icons.grade_outlined,
                value: _grades.length.toString(),
                subLabel: moyenne != null
                    ? 'Moy. ${moyenne.toStringAsFixed(1)}/20'
                    : 'Aucune note',
                color: moyenne == null
                    ? textGrey
                    : moyenne >= 10
                        ? successGreen
                        : dangerRed,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => GradesScreen(
                            studentId: auth.userId ?? '',
                            studentName: fullName))),
              ),
            ]),

            const SizedBox(height: 20),

            // Dernières notes
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Dernières notes',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark)),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => GradesScreen(
                            studentId: auth.userId ?? '',
                            studentName: fullName))),
                child: const Text('Voir tout'),
              ),
            ]),
            const SizedBox(height: 8),

            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator()))
            else if (_grades.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [
                  Icon(Icons.assignment_outlined, color: textGrey, size: 20),
                  SizedBox(width: 10),
                  Text('Aucune note ce trimestre',
                      style: TextStyle(color: textGrey)),
                ]),
              )
            else
              ..._grades.take(4).map((g) {
                final val = (g['value'] as num).toDouble();
                final isGood = val >= 10;
                final subject = g['subject'] as String? ?? '';
                final evalType = g['evalType'] as String? ?? '';
                final color = _subjectColor(subject);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(evalType,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(subject,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                    Text('${val.toStringAsFixed(1)}/20',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isGood ? successGreen : dangerRed)),
                  ]),
                );
              }),

            const SizedBox(height: 20),

            // Actions rapides
            const Text('Actions rapides',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),

            Row(children: [
              _ActionBtn(
                  icon: Icons.assignment_outlined,
                  label: 'Mes notes',
                  color: infoBlue,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GradesScreen(
                              studentId: auth.userId ?? '',
                              studentName: fullName)))),
              const SizedBox(width: 12),
              _ActionBtn(
                  icon: Icons.event_busy_outlined,
                  label: 'Absences',
                  color: dangerRed,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AttendanceHistoryScreen(history: [])))),
              const SizedBox(width: 12),
              _ActionBtn(
                  icon: Icons.calendar_view_week,
                  label: 'Mon EDT',
                  color: const Color(0xFF7C3AED),
                  onTap: () {}),
            ]),

            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value, subLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.subLabel,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            Text(subLabel,
                style: const TextStyle(color: textGrey, fontSize: 11)),
          ]),
        ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
