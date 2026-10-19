import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/services/subjects_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dio_error_message.dart';
import '../../grades/data/grade_model.dart';

/// Gestion du catalogue matières (aligné web `/matieres`).
class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  bool _loading = true;
  bool _showInactive = false;
  String? _error;
  List<Subject> _rows = [];

  bool get _canWrite {
    final role = ref.read(authProvider).role;
    return role == UserRole.admin ||
        role == UserRole.founder ||
        role == UserRole.director ||
        role == UserRole.censor;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _err(Object e) {
    if (e is DioException) {
      return dioErrorMessage(e, fallback: 'Erreur matières');
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows =
          await SubjectsApiService.list(includeInactive: _showInactive);
      _rows = rows;
    } catch (e) {
      _rows = [];
      _error = _err(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final nameCtrl = TextEditingController();
    final coefCtrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle matière'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
              autofocus: true,
            ),
            TextField(
              controller: coefCtrl,
              decoration: const InputDecoration(labelText: 'Coefficient'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Créer')),
        ],
      ),
    );
    if (ok != true) return;
    final coef = int.tryParse(coefCtrl.text.trim()) ?? 0;
    if (nameCtrl.text.trim().isEmpty || coef < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et coefficient (≥1) requis')),
      );
      return;
    }
    try {
      await SubjectsApiService.create(
        name: nameCtrl.text.trim(),
        coefficient: coef,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_err(e))));
    }
  }

  Future<void> _edit(Subject s) async {
    if (s.id == null) return;
    final nameCtrl = TextEditingController(text: s.name);
    final coefCtrl = TextEditingController(text: '${s.coefficient}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier la matière'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: coefCtrl,
              decoration: const InputDecoration(labelText: 'Coefficient'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok != true) return;
    final coef = int.tryParse(coefCtrl.text.trim()) ?? 0;
    if (nameCtrl.text.trim().isEmpty || coef < 1) return;
    try {
      await SubjectsApiService.update(
        s.id!,
        name: nameCtrl.text.trim(),
        coefficient: coef,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_err(e))));
    }
  }

  Future<void> _toggleActive(Subject s) async {
    if (s.id == null) return;
    try {
      await SubjectsApiService.update(s.id!, isActive: !s.isActive);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_err(e))));
    }
  }

  Future<void> _delete(Subject s) async {
    if (s.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer « ${s.name} » du catalogue ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: dangerRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SubjectsApiService.remove(s.id!);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_err(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Matières'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _showInactive ? 'Masquer inactives' : 'Voir inactives',
            icon: Icon(_showInactive
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
            onPressed: () {
              setState(() => _showInactive = !_showInactive);
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: _canWrite
          ? FloatingActionButton(
              onPressed: _create,
              backgroundColor: primaryBlue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: dangerRed)),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : _rows.isEmpty
                  ? const Center(child: Text('Aucune matière'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final s = _rows[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: s.isActive
                                    ? primaryBlue.withValues(alpha: 0.15)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: s.isActive
                                              ? textDark
                                              : textGrey,
                                          decoration: s.isActive
                                              ? null
                                              : TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Text(
                                        'Coefficient ${s.coefficient}'
                                        '${s.isActive ? '' : ' · inactive'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_canWrite) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20),
                                    onPressed: () => _edit(s),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      s.isActive
                                          ? Icons.toggle_on
                                          : Icons.toggle_off,
                                      color: s.isActive
                                          ? successGreen
                                          : textGrey,
                                    ),
                                    onPressed: () => _toggleActive(s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: dangerRed),
                                    onPressed: () => _delete(s),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
