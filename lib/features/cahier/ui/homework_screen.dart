import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/cahier_api_service.dart';
import '../../../core/theme/app_colors.dart';

/// Liste des devoirs (élève ou parent).
class HomeworkScreen extends StatefulWidget {
  final bool isParent;
  final String? studentId;

  const HomeworkScreen({super.key, this.isParent = false, this.studentId});

  factory HomeworkScreen.forStudent() =>
      const HomeworkScreen(isParent: false);

  factory HomeworkScreen.forParent({String? studentId}) =>
      HomeworkScreen(isParent: true, studentId: studentId);

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _showPast = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = widget.isParent
          ? await CahierApiService.getMyChildHomework(
              studentId: widget.studentId,
            )
          : await CahierApiService.getMyHomework();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les travaux à rendre';
          _loading = false;
        });
      }
    }
  }

  List<dynamic> get _items {
    if (_data == null) return [];
    final key = _showPast ? 'past' : 'upcoming';
    return (_data![key] as List<dynamic>?) ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Travail à rendre'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: dangerRed)),
                      TextButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('À faire'),
                              selected: !_showPast,
                              onSelected: (_) =>
                                  setState(() => _showPast = false),
                              selectedColor: primaryBlue.withValues(alpha: 0.15),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Passés'),
                              selected: _showPast,
                              onSelected: (_) =>
                                  setState(() => _showPast = true),
                              selectedColor: primaryBlue.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _items.isEmpty
                          ? Center(
                              child: Text(
                                _showPast
                                    ? 'Aucun travail passé'
                                    : 'Aucun travail à rendre',
                                style: const TextStyle(color: textGrey),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                itemCount: _items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) =>
                                    _HomeworkTile(item: _items[i]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _HomeworkTile extends StatelessWidget {
  final dynamic item;
  const _HomeworkTile({required this.item});

  String _formatDate(dynamic raw) {
    if (raw == null) return 'Date non fixée';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    return DateFormat('EEE d MMM yyyy', 'fr_FR').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final subject = item['subject']?.toString() ?? 'Matière';
    final desc = item['description']?.toString() ?? '';
    final due = item['dueDate'];
    final teacher = item['teacher']?.toString();
    final isOverdue = item['status'] == 'past';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? textGrey.withValues(alpha: 0.3)
              : primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(subject,
                    style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const Spacer(),
              Icon(
                Icons.event_outlined,
                size: 16,
                color: isOverdue ? textGrey : warningYellow,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(due),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOverdue ? textGrey : textDark,
                ),
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(fontSize: 13, color: textDark)),
          ],
          if (teacher != null && teacher.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Par $teacher',
                style: const TextStyle(fontSize: 11, color: textGrey)),
          ],
        ],
      ),
    );
  }
}
