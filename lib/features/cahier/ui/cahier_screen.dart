import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/cahier_api_service.dart';
import '../../../core/services/teacher_api_service.dart';

class CahierScreen extends ConsumerStatefulWidget {
  const CahierScreen({super.key});

  @override
  ConsumerState<CahierScreen> createState() => _CahierScreenState();
}

class _CahierScreenState extends ConsumerState<CahierScreen> {
  List<dynamic> _classes = [];
  String? _selectedClassId;
  String _selectedClassName = '';
  String _trimestre = 'T1';
  List<dynamic> _entries = [];
  bool _loading = true;
  bool _showForm = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), _loadClasses);
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await TeacherApiService.getMyClasses()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _classes = classes;
        if (classes.isNotEmpty) {
          _selectedClassId = classes[0]['id'] as String;
          _selectedClassName = classes[0]['name'] as String;
        }
      });
      await _loadEntries();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Impossible de charger les classes. Vérifiez votre connexion.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Impossible de charger les classes du cahier de texte'),
            backgroundColor: dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _loadEntries() async {
    if (_selectedClassId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await CahierApiService.getByClass(_selectedClassId!,
              trimestre: _trimestre)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Impossible de charger le cahier de texte. Tirez pour actualiser.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de chargement du cahier de texte'),
            backgroundColor: dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _emargement(String id) async {
    try {
      await CahierApiService.emargement(id);
      setState(() {
        _entries = _entries.map((e) {
          if (e['id'] == id) {
            return {
              ...e,
              'isEmarge': true,
              'emargeAt': DateTime.now().toIso8601String()
            };
          }
          return e;
        }).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Émargement enregistré'),
              backgroundColor: successGreen),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de l\'émargement. Réessayez.'),
            backgroundColor: dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nonEmarges = _entries.where((e) => e['isEmarge'] != true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Cahier de texte',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
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
              onPressed: _loadEntries),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showForm = !_showForm),
        backgroundColor: primaryBlue,
        child: Icon(_showForm ? Icons.close : Icons.add, color: Colors.white),
      ),
      body: Column(children: [
        if (_error != null)
          Material(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    onPressed: _selectedClassId == null
                        ? _loadClasses
                        : _loadEntries,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        // ── Filtres ────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            // Sélecteur classe
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButton<String>(
                  value: _selectedClassId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                  onChanged: (val) {
                    if (val == null) return;
                    final cls = _classes.firstWhere((c) => c['id'] == val);
                    setState(() {
                      _selectedClassId = val;
                      _selectedClassName = cls['name'] as String;
                    });
                    _loadEntries();
                  },
                  items: _classes
                      .map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                          value: c['id'] as String,
                          child: Text(c['name'] as String)))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Sélecteur trimestre
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButton<String>(
                value: _trimestre,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _trimestre = val);
                  _loadEntries();
                },
                items: const [
                  DropdownMenuItem(value: 'T1', child: Text('T1')),
                  DropdownMenuItem(value: 'T2', child: Text('T2')),
                  DropdownMenuItem(value: 'T3', child: Text('T3')),
                ],
              ),
            ),
          ]),
        ),

        // ── Alerte non émargés ─────────────────────────────────────────
        if (nonEmarges > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: warningYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: warningYellow.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_outlined,
                  color: warningYellow, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                '$nonEmarges séance(s) non émargée(s)',
                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
              )),
            ]),
          ),

        // ── Formulaire nouvelle entrée ─────────────────────────────────
        if (_showForm)
          _CahierForm(
            classId: _selectedClassId ?? '',
            trimestre: _trimestre,
            onSaved: () {
              setState(() => _showForm = false);
              _loadEntries();
            },
          ),

        // ── Liste des entrées ──────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _entries.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.book_outlined,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Aucune entrée pour $_selectedClassName',
                          style: TextStyle(color: Colors.grey.shade500)),
                      Text('Trimestre $_trimestre',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _entries.length,
                      itemBuilder: (ctx, i) => _CahierCard(
                        entry: _entries[i],
                        onEmargement: () =>
                            _emargement(_entries[i]['id'] as String),
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ── Formulaire nouvelle entrée ─────────────────────────────────────────────
class _CahierForm extends StatefulWidget {
  final String classId;
  final String trimestre;
  final VoidCallback onSaved;

  const _CahierForm(
      {required this.classId, required this.trimestre, required this.onSaved});

  @override
  State<_CahierForm> createState() => _CahierFormState();
}

class _CahierFormState extends State<_CahierForm> {
  final _subjectCtrl = TextEditingController();
  final _planCtrl = TextEditingController();
  final _prochainCtrl = TextEditingController();
  final _devoirCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _dateRemise;
  bool _saving = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _planCtrl.dispose();
    _prochainCtrl.dispose();
    _devoirCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _save() async {
    if (_subjectCtrl.text.trim().isEmpty || _planCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Matière et plan du cours obligatoires'),
            backgroundColor: dangerRed),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await CahierApiService.create({
        'classId': widget.classId,
        'subject': _subjectCtrl.text.trim(),
        'date': _date.toIso8601String(),
        'trimestre': widget.trimestre,
        'planCours': _planCtrl.text.trim(),
        'prochainCours': _prochainCtrl.text.trim().isEmpty
            ? null
            : _prochainCtrl.text.trim(),
        'devoirDescription':
            _devoirCtrl.text.trim().isEmpty ? null : _devoirCtrl.text.trim(),
        'devoirDateRemise': _dateRemise?.toIso8601String(),
      });
      if (mounted) widget.onSaved();
    } catch (e) {
      debugPrint('ECOLE+ cahier save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Nouvelle entrée',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          // Date
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030));
              if (d != null) setState(() => _date = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 14, color: primaryBlue),
                const SizedBox(width: 4),
                Text(_fmtDate(_date),
                    style: const TextStyle(
                        fontSize: 12,
                        color: primaryBlue,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Matière
        _Field(
            controller: _subjectCtrl,
            label: 'Matière *',
            hint: 'ex: Mathématiques'),
        const SizedBox(height: 10),

        // Plan du cours
        _Field(
            controller: _planCtrl,
            label: 'Plan du cours *',
            hint: 'Ce qui a été fait aujourd\'hui...',
            maxLines: 3),
        const SizedBox(height: 10),

        // Prochain cours
        _Field(
            controller: _prochainCtrl,
            label: 'Prochain cours',
            hint: 'Ce qui sera fait au prochain cours...',
            maxLines: 2),
        const SizedBox(height: 10),

        // Devoir
        _Field(
            controller: _devoirCtrl,
            label: 'Devoir donné',
            hint: 'Description du devoir...',
            maxLines: 2),
        const SizedBox(height: 8),

        // Date remise
        Row(children: [
          const Text('Date de remise :',
              style: TextStyle(fontSize: 12, color: textGrey)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030));
              if (d != null) setState(() => _dateRemise = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _dateRemise != null
                    ? warningYellow.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _dateRemise != null
                        ? warningYellow
                        : Colors.grey.shade300),
              ),
              child: Text(
                _dateRemise != null
                    ? _fmtDate(_dateRemise!)
                    : 'Choisir une date',
                style: TextStyle(
                    fontSize: 12,
                    color: _dateRemise != null
                        ? const Color(0xFF92400E)
                        : Colors.grey.shade500),
              ),
            ),
          ),
        ]),

        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Enregistrer',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}

// ── Carte entrée cahier ────────────────────────────────────────────────────
class _CahierCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onEmargement;

  const _CahierCard({required this.entry, required this.onEmargement});

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const mois = [
      'jan',
      'fév',
      'mar',
      'avr',
      'mai',
      'jun',
      'jul',
      'aoû',
      'sep',
      'oct',
      'nov',
      'déc'
    ];
    return '${jours[d.weekday - 1]} ${d.day} ${mois[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isEmarge = entry['isEmarge'] as bool? ?? false;
    final hasDevoir = entry['devoirDescription'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        // En-tête
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(entry['subject'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryBlue)),
                  Text(_fmtDate(entry['date'] as String? ?? ''),
                      style: const TextStyle(fontSize: 11, color: textGrey)),
                ])),
            if (hasDevoir)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: warningYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Devoir',
                    style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 8),
            // Émargement
            isEmarge
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_outline,
                          size: 14, color: successGreen),
                      SizedBox(width: 4),
                      Text('Émargé',
                          style: TextStyle(
                              fontSize: 11,
                              color: successGreen,
                              fontWeight: FontWeight.w600)),
                    ]),
                  )
                : GestureDetector(
                    onTap: onEmargement,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: dangerRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: dangerRed.withValues(alpha: 0.3)),
                      ),
                      child:
                          const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.edit_outlined, size: 14, color: dangerRed),
                        SizedBox(width: 4),
                        Text('Émarger',
                            style: TextStyle(
                                fontSize: 11,
                                color: dangerRed,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
          ]),
        ),

        // Corps — les 3 colonnes
        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Plan du cours
            _Section(
                title: 'Plan du cours',
                content: entry['planCours'] as String? ?? '',
                color: primaryBlue),

            if (entry['prochainCours'] != null) ...[
              const SizedBox(height: 10),
              _Section(
                  title: 'Prochain cours',
                  content: entry['prochainCours'] as String,
                  color: const Color(0xFF7C3AED)),
            ],

            if (hasDevoir) ...[
              const SizedBox(height: 10),
              _Section(
                title: 'Devoir',
                content: entry['devoirDescription'] as String,
                color: warningYellow,
                suffix: entry['devoirDateRemise'] != null
                    ? '📅 À rendre le ${_fmtDate(entry['devoirDateRemise'] as String)}'
                    : null,
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── Widgets utilitaires ────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title, content;
  final Color color;
  final String? suffix;

  const _Section(
      {required this.title,
      required this.content,
      required this.color,
      this.suffix});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Text(content,
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
      if (suffix != null) ...[
        const SizedBox(height: 4),
        Text(suffix!,
            style: const TextStyle(fontSize: 11, color: Color(0xFF92400E))),
      ],
    ]);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final int maxLines;

  const _Field(
      {required this.controller,
      required this.label,
      required this.hint,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: textGrey)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5)),
        ),
      ),
    ]);
  }
}
