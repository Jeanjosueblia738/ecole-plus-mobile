import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/class_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';

class ClassManagementScreen extends ConsumerWidget {
  const ClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesByCycle = ref.watch(classesByCycleProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Gestion des classes'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: () => _showClassForm(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: classesByCycle.isEmpty
          ? const Center(
              child: Text('Aucune classe configurée',
                  style: TextStyle(color: textGrey)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: classesByCycle.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── En-tête cycle ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                              '${entry.value.length} classe${entry.value.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: textGrey, fontSize: 13)),
                        ],
                      ),
                    ),
                    // ── Cartes classes ──────────────────────────
                    ...entry.value.map((c) {
                      final studentCount = ref
                          .watch(studentProvider)
                          .where((s) => s.className == c.name)
                          .length;
                      return _ClassCard(
                        schoolClass: c,
                        studentCount: studentCount,
                        onEdit: () => _showClassForm(context, ref, existing: c),
                        onDelete: () =>
                            _confirmDelete(context, ref, c.id, c.name),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ),
    );
  }

  void _showClassForm(BuildContext context, WidgetRef ref,
      {SchoolClass? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ClassFormSheet(existing: existing, ref: ref),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la classe'),
        content: Text('Supprimer "$name" ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: dangerRed),
            onPressed: () async {
              await ref.read(classProvider.notifier).remove(id);
              if (!context.mounted) return;
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

// ── Carte classe ───────────────────────────────────────────────────────────
class _ClassCard extends StatelessWidget {
  final SchoolClass schoolClass;
  final int studentCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassCard({
    required this.schoolClass,
    required this.studentCount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ratio =
        schoolClass.capacity > 0 ? studentCount / schoolClass.capacity : 0.0;
    final isFull = ratio >= 0.9;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Icône
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.class_, color: primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schoolClass.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$studentCount / ${schoolClass.capacity} élèves',
                      style: TextStyle(
                          fontSize: 12, color: isFull ? dangerRed : textGrey),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          backgroundColor: primaryBlue.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              isFull ? dangerRed : primaryBlue),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ])),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, size: 16, color: dangerRed),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: dangerRed)),
                  ])),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Formulaire ajout/modif classe ──────────────────────────────────────────
class _ClassFormSheet extends StatefulWidget {
  final SchoolClass? existing;
  final WidgetRef ref;

  const _ClassFormSheet({this.existing, required this.ref});

  @override
  State<_ClassFormSheet> createState() => _ClassFormSheetState();
}

class _ClassFormSheetState extends State<_ClassFormSheet> {
  final _nameCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  String _level = kAllLevels.first;
  String _cycle = 'Collège';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _capCtrl.text = widget.existing!.capacity.toString();
      _level = widget.existing!.level;
      _cycle = widget.existing!.cycle;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final capacity = int.tryParse(_capCtrl.text) ?? 40;

    final c = SchoolClass(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      level: _level,
      cycle: _cycle,
      capacity: capacity,
    );

    if (widget.existing == null) {
      await widget.ref.read(classProvider.notifier).add(c);
    } else {
      await widget.ref.read(classProvider.notifier).update(c);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null
                ? 'Ajouter une classe'
                : 'Modifier la classe',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Nom de la classe (ex: 3ème B)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _level,
                decoration: InputDecoration(
                  labelText: 'Niveau',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                items: kAllLevels
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _level = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _cycle,
                decoration: InputDecoration(
                  labelText: 'Cycle',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                items: ['Collège', 'Lycée']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _cycle = v!),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _capCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Capacité (nombre d\'élèves)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text(
                widget.existing == null ? 'Ajouter' : 'Enregistrer',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
