import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/services/finance_api_service.dart';
import '../../../core/theme/app_colors.dart';

/// Scan QR collé sur le bureau de la classe (arrivée / fin de cours).
class TeacherQrScanScreen extends StatefulWidget {
  const TeacherQrScanScreen({super.key});

  @override
  State<TeacherQrScanScreen> createState() => _TeacherQrScanScreenState();
}

class _TeacherQrScanScreenState extends State<TeacherQrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _busy = false;
  String? _lastPayload;
  Map<String, dynamic>? _lastResult;
  String? _error;
  DateTime? _lastScanAt;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;

    // Même QR : bloquer seulement après CLOCK_OUT, ou pendant le cooldown post-scan
    if (raw == _lastPayload && _lastResult != null) {
      final lastAction = _lastResult!['action']?.toString();
      if (lastAction == 'CLOCK_OUT') return;
      // CLOCK_IN → autoriser le 2e scan (sortie) après un court délai
      if (_lastScanAt != null &&
          DateTime.now().difference(_lastScanAt!) <
              const Duration(seconds: 3)) {
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
      _lastPayload = raw;
      _lastScanAt = DateTime.now();
    });

    try {
      await _controller.stop();
      final data = await FinanceApiService.qrScan(
        payload: raw.trim(),
      );
      if (!mounted) return;
      setState(() => _lastResult = data);
      final msg = data['message']?.toString() ?? 'Scan enregistré';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _error = msg;
        _lastResult = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: dangerRed),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) {
          try {
            await _controller.start();
          } catch (_) {}
        }
      }
    }
  }

  String _fmtDt(dynamic v) {
    if (v == null) return '—';
    try {
      final d = DateTime.parse(v.toString()).toLocal();
      return DateFormat('HH:mm:ss').format(d);
    } catch (_) {
      return v.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _lastResult?['session'] is Map
        ? Map<String, dynamic>.from(_lastResult!['session'] as Map)
        : null;
    final action = _lastResult?['action']?.toString();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR classe'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                if (_busy)
                  const ColoredBox(
                    color: Colors.black54,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black54,
                    padding: const EdgeInsets.all(12),
                    child: const Text(
                      'Scannez le QR collé sur le bureau.\n'
                      '1er scan = arrivée · 2e scan = fin de cours\n'
                      'Heures = GMT Côte d’Ivoire (serveur)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF8FAFF),
              padding: const EdgeInsets.all(16),
              child: session == null
                  ? Center(
                      child: Text(
                        _error ??
                            'En attente du scan…\nActivez la date/heure automatique.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: textGrey),
                      ),
                    )
                  : ListView(
                      children: [
                        Text(
                          action == 'CLOCK_IN'
                              ? 'Arrivée enregistrée'
                              : 'Fin de cours enregistrée',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: action == 'CLOCK_IN'
                                ? primaryBlue
                                : successGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow('Matière / séance', session['subject']),
                        _InfoRow('Classe', session['className']),
                        _InfoRow('Salle', session['room'] ?? '—'),
                        _InfoRow(
                          'Créneau prévu',
                          '${session['plannedStart']} – ${session['plannedEnd']}',
                        ),
                        _InfoRow(
                          'Heure d’arrivée',
                          _fmtDt(session['arrivalAt']),
                        ),
                        _InfoRow(
                          'Heure de fin',
                          session['endAt'] != null
                              ? _fmtDt(session['endAt'])
                              : 'À renseigner au 2e scan',
                        ),
                        if (session['actualMinutes'] != null)
                          _InfoRow(
                            'Durée pointée',
                            '${session['actualMinutes']} min',
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: textGrey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '—',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: textDark,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
