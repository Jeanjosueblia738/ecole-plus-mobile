import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/timetable_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/timetable_model.dart';
import 'timetable_slot_form.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  final String className;
  final String? classId;
  final bool canEdit; // true pour admin

  const TimetableScreen({
    super.key,
    required this.className,
    this.classId,
    this.canEdit = false,
  });

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedDay = _todayIndex();

  static int _todayIndex() {
    final wd = DateTime.now().weekday;
    return wd <= 6 ? wd - 1 : 0; // 0=Lundi
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: WeekDay.values.length,
      vsync: this,
      initialIndex: _selectedDay,
    );
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _selectedDay = _tabCtrl.index);
      }
    });
    Future.microtask(_reload);
  }

  Future<void> _reload() async {
    final notifier = ref.read(timetableProvider.notifier);
    final classId = widget.classId;
    if (classId != null && classId.isNotEmpty) {
      await notifier.loadForClass(classId, className: widget.className);
    } else {
      await notifier.load();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si chargé via classId API, tous les créneaux du state concernent cette classe
    final entries = widget.classId != null && widget.classId!.isNotEmpty
        ? ref.watch(timetableProvider)
        : ref.watch(timetableByClassProvider(widget.className));
    final loadError = ref.read(timetableProvider.notifier).error;
    final today = WeekDay.values[_selectedDay];
    final dayEntries = entries.where((e) => e.day == today).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text('EDT — ${widget.className}'),
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
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: WeekDay.values.map((d) => Tab(text: d.short)).toList(),
        ),
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton(
              backgroundColor: primaryBlue,
              onPressed: () => _showAddSlot(context),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          if (loadError != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(loadError,
                        style: TextStyle(
                            color: Colors.red.shade800, fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: dayEntries.isEmpty
                ? _EmptyDay(day: today)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dayEntries.length,
                    itemBuilder: (context, index) {
                      final entry = dayEntries[index];
                      final isNow = _isCurrentSlot(entry);
                      return _EntryCard(
                        entry: entry,
                        isNow: isNow,
                        canEdit: widget.canEdit,
                        onDelete: widget.canEdit
                            ? () => ref
                                .read(timetableProvider.notifier)
                                .removeEntry(entry.id)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentSlot(TimetableEntry entry) {
    final now = DateTime.now();
    final today = WeekDay.values[_selectedDay];
    if (WeekDay.values[now.weekday - 1] != today) return false;

    final parts = entry.startTime.split(':');
    final startMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final endParts = entry.endTime.split(':');
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final nowMin = now.hour * 60 + now.minute;

    return nowMin >= startMin && nowMin < endMin;
  }

  void _showAddSlot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => TimetableSlotForm(
        className: widget.className,
        initialDay: WeekDay.values[_selectedDay],
      ),
    );
  }
}

// ── Carte créneau ──────────────────────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final TimetableEntry entry;
  final bool isNow;
  final bool canEdit;
  final VoidCallback? onDelete;

  const _EntryCard({
    required this.entry,
    required this.isNow,
    required this.canEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNow ? entry.color : border,
          width: isNow ? 2 : 1,
        ),
        boxShadow: isNow ? elevatedShadow : cardShadow,
      ),
      child: Row(
        children: [
          // ── Bande couleur + heure ───────────────────────────────
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(13)),
            ),
            child: Column(
              children: [
                Text(
                  entry.startTime,
                  style: TextStyle(
                    color: entry.color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: entry.color.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
                Text(
                  entry.endTime,
                  style: TextStyle(
                    color: entry.color.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ── Infos cours ─────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.subject,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: entry.color,
                          ),
                        ),
                      ),
                      if (isNow)
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: textGrey),
                      const SizedBox(width: 4),
                      Text(entry.teacherName,
                          style:
                              const TextStyle(color: textGrey, fontSize: 12)),
                      if (entry.room != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.room_outlined,
                            size: 13, color: textGrey),
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
          ),

          // ── Bouton supprimer ─────────────────────────────────────
          if (canEdit && onDelete != null)
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: dangerRed, size: 18),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce créneau ?'),
        content:
            Text('${entry.subject} — ${entry.startTime} à ${entry.endTime}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: dangerRed),
            onPressed: () {
              onDelete?.call();
              Navigator.pop(context);
            },
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Jour vide ──────────────────────────────────────────────────────────────
class _EmptyDay extends StatelessWidget {
  final WeekDay day;
  const _EmptyDay({required this.day});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_outlined,
              size: 56,
              color: day == WeekDay.samedi ? successGreen : textLight),
          const SizedBox(height: 12),
          Text(
            day == WeekDay.samedi
                ? 'Samedi libre !'
                : 'Aucun cours ${day.label}',
            style: TextStyle(
                color: day == WeekDay.samedi ? successGreen : textGrey,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
