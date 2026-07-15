import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/providers/grade_provider.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'parent_grades_screen.dart';
import '../../student/ui/attendance_history_screen.dart';

class ParentChildScreen extends ConsumerStatefulWidget {
  const ParentChildScreen({super.key});

  @override
  ConsumerState<ParentChildScreen> createState() => _ParentChildScreenState();
}

class _ParentChildScreenState extends ConsumerState<ParentChildScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_prime);
  }

  Future<void> _prime() async {
    final child = await ref.read(parentChildAsyncProvider.future);
    if (child == null) return;
    await Future.wait([
      ref.read(gradeProvider.notifier).loadForStudent(
            child.id,
            trimestre: '1er',
            studentName: child.fullName,
            className: child.className,
          ),
      ref.read(attendanceProvider.notifier).loadForStudent(
            child.id,
            studentName: child.fullName,
            className: child.className,
          ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final childAsync = ref.watch(parentChildAsyncProvider);
    final child = childAsync.valueOrNull;
    final stats = ref.watch(childStatsProvider('1er'));

    if (childAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (child == null) {
      return const Scaffold(
        body: Center(child: Text('Aucun enfant lié')),
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar avec avatar ───────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, Color(0xFF3B6FD4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        child.fullName[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(child.fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(child.className,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats trimestre ──────────────────────────
                  const Text('1er Trimestre',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _StatBox(
                        label: 'Absences',
                        value: '${stats.totalAbsences}',
                        color: dangerRed),
                    const SizedBox(width: 10),
                    _StatBox(
                        label: 'Justifiées',
                        value: '${stats.absencesJustifiees}',
                        color: successGreen),
                    const SizedBox(width: 10),
                    _StatBox(
                        label: 'Moyenne',
                        value: stats.moyenneTrimestre != null
                            ? '${stats.moyenneTrimestre!.toStringAsFixed(1)}/20'
                            : '—',
                        color: stats.moyenneTrimestre != null &&
                                stats.moyenneTrimestre! >= 10
                            ? successGreen
                            : dangerRed),
                  ]),

                  const SizedBox(height: 24),

                  // ── Infos contact ────────────────────────────
                  const Text('Informations',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                  const SizedBox(height: 10),
                  _InfoTile(
                      icon: Icons.class_outlined,
                      label: 'Classe',
                      value: child.className),
                  _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Contact parent',
                      value: child.parentPhone),

                  const SizedBox(height: 24),

                  // ── Actions ──────────────────────────────────
                  const Text('Actions',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.grade_outlined,
                        label: 'Voir les notes',
                        color: infoBlue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ParentGradesScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.event_busy_outlined,
                        label: 'Voir les absences',
                        color: dangerRed,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AttendanceHistoryScreen(history: [])),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: textGrey)),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textGrey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: textGrey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap,
    );
  }
}
