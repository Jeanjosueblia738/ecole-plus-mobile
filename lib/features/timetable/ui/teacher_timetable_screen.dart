import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/timetable_provider.dart';
import '../../../core/providers/teacher_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/timetable_model.dart';

// Vue EDT de l'enseignant — toutes ses classes groupées par jour
class TeacherTimetableScreen extends ConsumerStatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  ConsumerState<TeacherTimetableScreen> createState() =>
      _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends ConsumerState<TeacherTimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static int _todayIndex() {
    final wd = DateTime.now().weekday;
    return wd <= 6 ? wd - 1 : 0;
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: WeekDay.values.length,
      vsync: this,
      initialIndex: _todayIndex(),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(teacherProfileProvider);
    final entries = ref.watch(timetableByTeacherProvider(profile.fullName));

    // Stats rapides
    final totalHours = entries.length; // 1 créneau ≈ 55min

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Mon emploi du temps'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: WeekDay.values.map((d) => Tab(text: d.short)).toList(),
        ),
      ),
      body: Column(
        children: [
          // ── Résumé semaine ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            color: primaryBlue.withValues(alpha: 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeekStat(
                  label: 'Cours / semaine',
                  value: '$totalHours',
                  icon: Icons.school_outlined,
                ),
                _WeekStat(
                  label: 'Classes',
                  value:
                      entries.map((e) => e.className).toSet().length.toString(),
                  icon: Icons.class_outlined,
                ),
                _WeekStat(
                  label: 'Matières',
                  value:
                      entries.map((e) => e.subject).toSet().length.toString(),
                  icon: Icons.book_outlined,
                ),
              ],
            ),
          ),

          // ── Grille par jour ────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: WeekDay.values.map((day) {
                final dayEntries = entries.where((e) => e.day == day).toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));

                if (dayEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          day == WeekDay.samedi
                              ? Icons.weekend_outlined
                              : Icons.free_breakfast_outlined,
                          size: 48,
                          color: textLight,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          day == WeekDay.samedi
                              ? 'Samedi libre'
                              : 'Pas de cours ${day.label}',
                          style: const TextStyle(color: textGrey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayEntries.length,
                  itemBuilder: (context, index) {
                    final entry = dayEntries[index];
                    return _TeacherEntryCard(entry: entry);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _WeekStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: primaryBlue, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
        Text(label, style: const TextStyle(color: textGrey, fontSize: 11)),
      ],
    );
  }
}

class _TeacherEntryCard extends StatelessWidget {
  final TimetableEntry entry;

  const _TeacherEntryCard({required this.entry});

  bool get _isNow {
    final now = DateTime.now();
    final todayEnum = WeekDay.values[now.weekday - 1];
    if (entry.day != todayEnum) return false;
    final startParts = entry.startTime.split(':');
    final endParts = entry.endTime.split(':');
    final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final nowMin = now.hour * 60 + now.minute;
    return nowMin >= startMin && nowMin < endMin;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isNow ? entry.color : border,
          width: _isNow ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Heure
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(entry.startTime,
                    style: TextStyle(
                        color: entry.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(entry.endTime,
                    style: TextStyle(
                        color: entry.color.withValues(alpha: 0.6),
                        fontSize: 11)),
              ],
            ),
          ),
          Container(
            width: 3,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: entry.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(entry.subject,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: entry.color,
                              fontSize: 14)),
                    ),
                    if (_isNow)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: entry.color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('En cours',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.class_outlined, size: 12, color: textGrey),
                    const SizedBox(width: 4),
                    Text(entry.className,
                        style: const TextStyle(color: textGrey, fontSize: 12)),
                    if (entry.room != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.room_outlined,
                          size: 12, color: textGrey),
                      const SizedBox(width: 4),
                      Text(entry.room!,
                          style:
                              const TextStyle(color: textGrey, fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
