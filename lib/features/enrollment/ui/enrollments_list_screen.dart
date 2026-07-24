import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/enrollments_api_service.dart';
import '../../../core/theme/app_colors.dart';

/// Liste des pré-inscriptions pour le secrétariat.
class EnrollmentsListScreen extends StatefulWidget {
  const EnrollmentsListScreen({super.key});

  @override
  State<EnrollmentsListScreen> createState() => _EnrollmentsListScreenState();
}

class _EnrollmentsListScreenState extends State<EnrollmentsListScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'PENDING';

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
      final data = await EnrollmentsApiService.list(
        status: _filter.isEmpty ? null : _filter,
      );
      if (mounted) {
        setState(() {
          _items = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les demandes';
          _loading = false;
        });
      }
    }
  }

  Future<void> _review(String id, String status) async {
    String? reason;
    if (status == 'REJECTED') {
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Motif du refus'),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'Optionnel'),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, ctrl.text),
                  child: const Text('Confirmer')),
            ],
          );
        },
      );
      if (reason == null) return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'APPROVED' ? 'Approuver' : 'Refuser'),
        content: Text(status == 'APPROVED'
            ? 'Créer le dossier élève à partir de cette demande ?'
            : 'Refuser cette demande de pré-inscription ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await EnrollmentsApiService.review(
        id,
        status: status,
        rejectionReason: reason?.trim().isEmpty == true ? null : reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'APPROVED'
                ? 'Demande approuvée'
                : 'Demande refusée'),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Color _statusColor(String? status) => switch (status) {
        'APPROVED' => successGreen,
        'REJECTED' => dangerRed,
        _ => warningYellow,
      };

  String _statusLabel(String? status) => switch (status) {
        'APPROVED' => 'Approuvée',
        'REJECTED' => 'Refusée',
        _ => 'En attente',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Pré-inscriptions'),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'En attente',
                  selected: _filter == 'PENDING',
                  onTap: () {
                    setState(() => _filter = 'PENDING');
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Toutes',
                  selected: _filter == '',
                  onTap: () {
                    setState(() => _filter = '');
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: const TextStyle(color: dangerRed)),
                            TextButton(
                                onPressed: _load,
                                child: const Text('Réessayer')),
                          ],
                        ),
                      )
                    : _items.isEmpty
                        ? const Center(
                            child: Text('Aucune demande',
                                style: TextStyle(color: textGrey)),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final item = _items[i];
                                final status =
                                    item['status']?.toString() ?? 'PENDING';
                                final name =
                                    '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}'
                                        .trim();
                                final created = item['createdAt'];
                                final dt = DateTime.tryParse(
                                    created?.toString() ?? '');
                                final dateStr = dt != null
                                    ? DateFormat('d MMM yyyy', 'fr_FR')
                                        .format(dt)
                                    : '';

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey.shade100),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _statusLabel(status),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _statusColor(status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item['levelRequested'] != null)
                                        Text(
                                          'Niveau : ${item['levelRequested']}',
                                          style: const TextStyle(
                                              fontSize: 12, color: textGrey),
                                        ),
                                      Text(
                                        'Parent : ${item['parentName'] ?? '—'} • ${item['parentPhone'] ?? ''}',
                                        style: const TextStyle(
                                            fontSize: 12, color: textGrey),
                                      ),
                                      if (dateStr.isNotEmpty)
                                        Text(dateStr,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: textGrey)),
                                      if (status == 'PENDING') ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => _review(
                                                    item['id'] as String,
                                                    'REJECTED'),
                                                child: const Text('Refuser'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => _review(
                                                    item['id'] as String,
                                                    'APPROVED'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      successGreen,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child:
                                                    const Text('Approuver'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF0D9488).withValues(alpha: 0.15),
    );
  }
}
