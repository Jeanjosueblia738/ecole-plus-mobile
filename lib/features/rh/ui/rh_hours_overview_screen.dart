import 'package:flutter/material.dart';
import '../../../core/services/finance_api_service.dart';
import '../../../core/theme/app_colors.dart';

/// Vue RH : récap heures enseignants du mois en cours.
class RhHoursOverviewScreen extends StatefulWidget {
  const RhHoursOverviewScreen({super.key});

  @override
  State<RhHoursOverviewScreen> createState() => _RhHoursOverviewScreenState();
}

class _RhHoursOverviewScreenState extends State<RhHoursOverviewScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _teachers = [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final now = DateTime.now();
    try {
      final sum = await FinanceApiService.hoursSummary(
        year: now.year,
        month: now.month,
      );
      setState(() {
        _teachers = (sum['teachers'] as List?) ?? [];
      });
    } catch (e) {
      setState(() {
        _teachers = [];
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmt(num n) =>
      '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text('Suivi heures · ${now.month}/${now.year}'),
        backgroundColor: const Color(0xFF0E7490),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: dangerRed),
                      ),
                    ),
                  if (_teachers.isEmpty && _error == null)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucune donnée d’heures ce mois.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textGrey),
                      ),
                    ),
                  ..._teachers.map((raw) {
                    final t = Map<String, dynamic>.from(raw as Map);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(t['name']?.toString() ?? '—'),
                        subtitle: Text(
                          'Prévu ${t['plannedMinutes'] ?? 0} min · '
                          'Fait ${t['taughtMinutes'] ?? 0} min · '
                          'Manqué ${t['shortfallMinutes'] ?? 0} min',
                        ),
                        trailing: Text(
                          _fmt((t['estimatedDeductionXof'] as num?) ?? 0),
                          style: const TextStyle(
                            color: dangerRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
