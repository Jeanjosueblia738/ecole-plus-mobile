import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/staff_presence_api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'campus_qr_scan_screen.dart';

/// Liste des pointages campus du jour (direction / vie scolaire).
class StaffPresenceTodayScreen extends StatefulWidget {
  const StaffPresenceTodayScreen({super.key});

  @override
  State<StaffPresenceTodayScreen> createState() =>
      _StaffPresenceTodayScreenState();
}

class _StaffPresenceTodayScreenState extends State<StaffPresenceTodayScreen> {
  bool _loading = true;
  List<dynamic> _rows = [];
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _rows = await StaffPresenceApiService.today();
    } catch (e) {
      _rows = [];
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    try {
      return DateFormat('HH:mm:ss')
          .format(DateTime.parse(v.toString()).toLocal());
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Présence personnel'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner QR campus',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CampusQrScanScreen(),
                ),
              );
              _load();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scanner'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CampusQrScanScreen()),
          );
          _load();
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                children: [
                  Text(
                    'Pointages du jour (${_rows.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: dangerRed),
                      ),
                    ),
                  if (_rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error != null
                            ? 'Liste indisponible.'
                            : 'Aucun pointage aujourd’hui.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: textGrey),
                      ),
                    ),
                  ..._rows.map((raw) {
                    final r = Map<String, dynamic>.from(raw as Map);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(r['personName']?.toString() ?? '—'),
                        subtitle: Text(r['role']?.toString() ?? ''),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'E ${_fmt(r['clockInAt'])}',
                              style: const TextStyle(
                                color: successGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'S ${_fmt(r['clockOutAt'])}',
                              style: const TextStyle(
                                color: primaryBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
