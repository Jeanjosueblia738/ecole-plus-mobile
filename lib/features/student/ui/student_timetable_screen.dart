import 'package:flutter/material.dart';
import '../../../core/services/parent_api_service.dart';
import '../../../core/services/student_api_service.dart';
import '../../../core/theme/app_colors.dart';

const _days = ['LUNDI', 'MARDI', 'MERCREDI', 'JEUDI', 'VENDREDI', 'SAMEDI'];
const _dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

class StudentTimetableScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() loader;
  final String titlePrefix;

  const StudentTimetableScreen({
    super.key,
    this.loader = StudentApiService.getMyTimetable,
    this.titlePrefix = 'EDT',
  });

  /// EDT de l'enfant (compte parent).
  factory StudentTimetableScreen.forParent({
    Key? key,
    String? studentId,
  }) {
    return StudentTimetableScreen(
      key: key,
      loader: () => ParentApiService.getChildTimetable(studentId: studentId),
      titlePrefix: 'EDT enfant',
    );
  }

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  static int _todayIndex() {
    final wd = DateTime.now().weekday;
    return wd <= 6 ? wd - 1 : 0;
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: _todayIndex(),
    );
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.loader();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger l\'emploi du temps';
        _loading = false;
      });
    }
  }

  List<dynamic> _slotsFor(String day) {
    final byDay = _data?['byDay'] as Map<String, dynamic>?;
    if (byDay != null && byDay[day] is List) {
      return List<dynamic>.from(byDay[day] as List);
    }
    final slots = _data?['slots'] as List<dynamic>? ?? [];
    return slots.where((s) => s['day'] == day).toList();
  }

  String get _className {
    final c = _data?['class'];
    if (c is Map) return (c['name'] as String?) ?? 'Ma classe';
    return 'Ma classe';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text('${widget.titlePrefix} — $_className'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _dayLabels.map((d) => Tab(text: d)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_busy_outlined,
                            size: 48, color: textGrey),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: textGrey)),
                        const SizedBox(height: 16),
                        TextButton(
                            onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabCtrl,
                  children: _days.map((day) {
                    final slots = _slotsFor(day)
                      ..sort((a, b) => ((a['startTime'] as String?) ?? '')
                          .compareTo((b['startTime'] as String?) ?? ''));
                    if (slots.isEmpty) {
                      return const Center(
                        child: Text('Aucun cours ce jour',
                            style: TextStyle(color: textGrey)),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: slots.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final s = slots[index] as Map<String, dynamic>;
                        final teacher = s['teacher'] as Map<String, dynamic>?;
                        final teacherName = teacher == null
                            ? '—'
                            : '${teacher['firstName'] ?? ''} ${teacher['lastName'] ?? ''}'
                                .trim();
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: primaryBlue.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: primaryBlue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s['subject'] as String? ?? 'Cours',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${s['startTime'] ?? ''} – ${s['endTime'] ?? ''}'
                                      '${s['room'] != null ? ' · ${s['room']}' : ''}',
                                      style: const TextStyle(
                                          color: textGrey, fontSize: 12),
                                    ),
                                    if (teacherName.isNotEmpty &&
                                        teacherName != '—')
                                      Text(
                                        teacherName,
                                        style: const TextStyle(
                                            color: textGrey, fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
    );
  }
}
