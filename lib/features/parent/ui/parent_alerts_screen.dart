import 'package:flutter/material.dart';
import '../../../core/services/parent_api_service.dart';
import '../../../core/theme/app_colors.dart';

class ParentAlertsScreen extends StatefulWidget {
  const ParentAlertsScreen({super.key});

  @override
  State<ParentAlertsScreen> createState() => _ParentAlertsScreenState();
}

class _ParentAlertsScreenState extends State<ParentAlertsScreen> {
  List<dynamic> _alerts = [];
  bool _loading = true;
  String? _error;

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
      final data = await ParentApiService.getMyAlerts();
      if (!mounted) return;
      setState(() {
        _alerts = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les alertes';
        _loading = false;
      });
    }
  }

  Color _toneFor(String? type) {
    if (type == 'OVERDUE') return dangerRed;
    if (type == 'UPCOMING_J7') return warningYellow;
    return primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Alertes de paiement'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: textGrey)),
                      TextButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _alerts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_outlined,
                              size: 56, color: textGrey),
                          SizedBox(height: 12),
                          Text('Aucune alerte pour le moment',
                              style: TextStyle(color: textGrey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _alerts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final a = _alerts[index] as Map<String, dynamic>;
                          final type = a['type'] as String?;
                          final color = _toneFor(type);
                          final fee = a['studentFee']?['fee'];
                          final student = a['studentFee']?['student'];
                          final studentName = student == null
                              ? ''
                              : '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'
                                  .trim();
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      type == 'OVERDUE'
                                          ? Icons.warning_amber_rounded
                                          : Icons.schedule_outlined,
                                      color: color,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        a['title'] as String? ?? 'Alerte',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                if (studentName.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(studentName,
                                      style: const TextStyle(
                                          color: textGrey, fontSize: 12)),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  a['message'] as String? ?? '',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                if (fee != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${fee['label'] ?? ''} — ${fee['amountXof'] ?? ''} FCFA',
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12),
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
