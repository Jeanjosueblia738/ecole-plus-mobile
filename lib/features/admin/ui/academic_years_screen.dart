import 'package:flutter/material.dart';
import '../../../core/services/academic_year_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/school_year.dart';

class AcademicYearsScreen extends StatefulWidget {
  const AcademicYearsScreen({super.key});

  @override
  State<AcademicYearsScreen> createState() => _AcademicYearsScreenState();
}

class _AcademicYearsScreenState extends State<AcademicYearsScreen> {
  List<Map<String, dynamic>> _years = [];
  bool _loading = true;
  String? _error;
  String? _message;
  final _labelCtrl = TextEditingController();
  String? _busyId;
  final Map<String, String> _cloneSource = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await AcademicYearApiService.getAll();
      final years = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      Map<String, dynamic>? current;
      for (final y in years) {
        if (y['isCurrent'] == true) {
          current = y;
          break;
        }
      }
      current ??= years.isNotEmpty ? years.first : null;
      if (current != null && current['label'] is String) {
        await setSelectedSchoolYear(current['label'] as String);
      }
      if (!mounted) return;
      setState(() {
        _years = years;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les années scolaires';
      });
    }
  }

  Future<void> _create() async {
    final label = _labelCtrl.text.trim().isEmpty
        ? calendarSchoolYear()
        : _labelCtrl.text.trim();
    try {
      await AcademicYearApiService.create(label: label);
      _labelCtrl.clear();
      setState(() => _message = 'Année créée');
      await _load();
    } catch (e) {
      setState(() => _error = 'Création impossible');
    }
  }

  Future<void> _activate(String id) async {
    setState(() => _busyId = id);
    try {
      final y = await AcademicYearApiService.activate(id);
      if (y['label'] is String) {
        await setSelectedSchoolYear(y['label'] as String);
      }
      setState(() => _message = 'Année activée');
      await _load();
    } catch (_) {
      setState(() => _error = 'Activation impossible');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _archive(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archiver ?'),
        content: const Text('Cette année passera en lecture seule.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Archiver')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busyId = id);
    try {
      await AcademicYearApiService.archive(id);
      setState(() => _message = 'Année archivée');
      await _load();
    } catch (_) {
      setState(() => _error = 'Archivage impossible');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _clone(String targetId) async {
    final sourceId = _cloneSource[targetId];
    if (sourceId == null || sourceId.isEmpty) {
      setState(() => _error = 'Choisissez une année source');
      return;
    }
    setState(() => _busyId = targetId);
    try {
      final res = await AcademicYearApiService.cloneClasses(
        targetYearId: targetId,
        sourceYearId: sourceId,
      );
      setState(() {
        _message =
            '${res['createdCount'] ?? 0} classe(s) clonée(s), ${res['skippedCount'] ?? 0} ignorée(s)';
      });
    } catch (_) {
      setState(() => _error = 'Clonage impossible');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _selectYear(String label) async {
    await setSelectedSchoolYear(label);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Année sélectionnée : $label')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Années scolaires'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_message!, style: const TextStyle(color: Colors.green)),
                  ),
                Text(
                  'Année UI : ${currentSchoolYear()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _labelCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nouvelle année',
                          hintText: calendarSchoolYear(),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _create,
                      style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                      child: const Text('Créer'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._years.map((y) {
                  final id = y['id'] as String;
                  final label = y['label'] as String? ?? '';
                  final status = y['status'] as String? ?? '';
                  final isCurrent = y['isCurrent'] == true;
                  final archived = status == 'ARCHIVED';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$label${isCurrent ? ' (courante)' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(status, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => _selectYear(label),
                                child: const Text('Sélectionner'),
                              ),
                              if (!archived && !isCurrent)
                                OutlinedButton(
                                  onPressed: _busyId == id
                                      ? null
                                      : () => _activate(id),
                                  child: const Text('Activer'),
                                ),
                              if (!archived)
                                OutlinedButton(
                                  onPressed:
                                      _busyId == id ? null : () => _archive(id),
                                  child: const Text('Archiver'),
                                ),
                            ],
                          ),
                          if (!archived) ...[
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _cloneSource[id],
                              decoration: const InputDecoration(
                                labelText: 'Cloner classes depuis',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: _years
                                  .where((o) => o['id'] != id)
                                  .map(
                                    (o) => DropdownMenuItem(
                                      value: o['id'] as String,
                                      child: Text(o['label'] as String? ?? ''),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _cloneSource[id] = v ?? ''),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed:
                                  _busyId == id ? null : () => _clone(id),
                              icon: const Icon(Icons.copy_all_outlined),
                              label: const Text('Cloner les classes'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
