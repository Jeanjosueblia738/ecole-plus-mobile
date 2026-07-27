import 'package:flutter/material.dart';
import '../../../core/services/staff_presence_api_service.dart';
import '../../../core/theme/app_colors.dart';

/// Alertes jour J — cours non pointés, remplacements, non assurés.
class PresenceAlertsScreen extends StatefulWidget {
  const PresenceAlertsScreen({super.key});

  @override
  State<PresenceAlertsScreen> createState() => _PresenceAlertsScreenState();
}

class _PresenceAlertsScreenState extends State<PresenceAlertsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _alerts;
  List<dynamic> _teachers = [];
  String? _busyId;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final a = await PresenceAlertsApiService.todayAlerts();
      List<dynamic> teachers = [];
      try {
        teachers = await PresenceAlertsApiService.listTeachers();
      } catch (_) {}
      setState(() {
        _alerts = a;
        _teachers = teachers;
      });
    } catch (_) {
      setState(() => _alerts = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _assign(String occurrenceId, String teacherId) async {
    setState(() => _busyId = occurrenceId);
    try {
      await PresenceAlertsApiService.assignSubstitute(
        occurrenceId: occurrenceId,
        substituteTeacherId: teacherId,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: dangerRed),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _report(String occurrenceId) async {
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Cours non assuré'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Motif'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Signaler'),
            ),
          ],
        );
      },
    );
    if (note == null) return;
    setState(() => _busyId = occurrenceId);
    try {
      await PresenceAlertsApiService.reportUncovered(
        occurrenceId: occurrenceId,
        note: note.isEmpty ? null : note,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: dangerRed),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _alerts?['summary'] as Map?;
    final unpointed = (_alerts?['unpointed'] as List?) ?? [];
    final overdue = (_alerts?['overdueCheckout'] as List?) ?? [];
    final uncovered = (_alerts?['uncovered'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Alertes jour J'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading && _alerts == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Kpi(
                          'Non pointés',
                          '${s?['unpointed'] ?? 0}',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Kpi(
                          'Sortie retard',
                          '${s?['overdueCheckout'] ?? 0}',
                          dangerRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Kpi(
                          'Non assurés',
                          '${s?['uncovered'] ?? 0}',
                          const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cours sans pointe',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (unpointed.isEmpty)
                    const Text('Aucun', style: TextStyle(color: textGrey)),
                  ...unpointed.map((raw) {
                    final o = Map<String, dynamic>.from(raw as Map);
                    final id = o['id']?.toString() ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${o['subject']} · ${o['className']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${o['teacherName']} · ${o['startTime']}-${o['endTime']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: textGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      labelText: 'Remplaçant',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _teachers
                                        .map((t) {
                                          final m = Map<String, dynamic>.from(
                                              t as Map);
                                          return DropdownMenuItem(
                                            value: m['id']?.toString(),
                                            child: Text(
                                              '${m['firstName']} ${m['lastName']}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        })
                                        .where((e) => e.value != null)
                                        .toList(),
                                    onChanged: _busyId == id
                                        ? null
                                        : (v) {
                                            if (v != null) _assign(id, v);
                                          },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed:
                                      _busyId == id ? null : () => _report(id),
                                  child: const Text('Non assuré'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text(
                    'Sorties non pointées',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...overdue.map((raw) {
                    final o = Map<String, dynamic>.from(raw as Map);
                    return ListTile(
                      dense: true,
                      title: Text('${o['subject']} · ${o['className']}'),
                      subtitle: Text('${o['teacherName']} · fin ${o['endTime']}'),
                    );
                  }),
                  if (overdue.isEmpty)
                    const Text('RAS', style: TextStyle(color: textGrey)),
                  const SizedBox(height: 16),
                  const Text(
                    'Cours non assurés',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...uncovered.map((raw) {
                    final o = Map<String, dynamic>.from(raw as Map);
                    return ListTile(
                      dense: true,
                      title: Text('${o['subject']} · ${o['className']}'),
                      subtitle: Text(
                        '${o['teacherName']}${o['note'] != null ? ' · ${o['note']}' : ''}',
                      ),
                    );
                  }),
                  if (uncovered.isEmpty)
                    const Text('RAS', style: TextStyle(color: textGrey)),
                ],
              ),
            ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: textGrey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
