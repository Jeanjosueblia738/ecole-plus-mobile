import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

/// Scan QR entrée campus — tout le personnel (entrée / sortie).
class CampusQrScanScreen extends StatefulWidget {
  const CampusQrScanScreen({super.key});

  @override
  State<CampusQrScanScreen> createState() => _CampusQrScanScreenState();
}

class _CampusQrScanScreenState extends State<CampusQrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _busy = false;
  String? _lastPayload;
  Map<String, dynamic>? _lastResult;
  String? _error;

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
    if (raw == _lastPayload && _lastResult != null) return;

    setState(() {
      _busy = true;
      _error = null;
      _lastPayload = raw;
    });

    try {
      await _controller.stop();
      final response = await ApiClient.instance.post(
        '/staff-presence/qr-scan',
        data: {
          'payload': raw.trim(),
          'clientTime': DateTime.now().toUtc().toIso8601String(),
        },
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      if (!mounted) return;
      setState(() => _lastResult = data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message']?.toString() ?? 'OK'),
          backgroundColor: successGreen,
        ),
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message'] ?? e.message)
          : e.message;
      final text =
          msg is List ? msg.join(' · ') : (msg?.toString() ?? 'Erreur');
      if (!mounted) return;
      setState(() {
        _error = text;
        _lastResult = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), backgroundColor: dangerRed),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
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

  String _fmt(dynamic v) {
    if (v == null) return '—';
    try {
      return DateFormat('HH:mm:ss')
          .format(DateTime.parse(v.toString()).toLocal());
    } catch (_) {
      return v.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final att = _lastResult?['attendance'] is Map
        ? Map<String, dynamic>.from(_lastResult!['attendance'] as Map)
        : null;
    final action = _lastResult?['action']?.toString();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Pointage personnel'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
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
                      'Scannez le QR entrée campus.\n'
                      '1er scan = entrée · 2e scan = sortie\n'
                      'Heures = horloge du téléphone',
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
              child: att == null
                  ? Center(
                      child: Text(
                        _error ?? 'En attente du scan…',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: textGrey),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action == 'CLOCK_IN'
                              ? 'Entrée enregistrée'
                              : 'Sortie enregistrée',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: action == 'CLOCK_IN'
                                ? primaryBlue
                                : successGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Nom : ${att['personName'] ?? '—'}'),
                        Text('Rôle : ${att['role'] ?? '—'}'),
                        Text('Entrée : ${_fmt(att['clockInAt'])}'),
                        Text(
                          'Sortie : ${att['clockOutAt'] != null ? _fmt(att['clockOutAt']) : 'À renseigner au 2e scan'}',
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
