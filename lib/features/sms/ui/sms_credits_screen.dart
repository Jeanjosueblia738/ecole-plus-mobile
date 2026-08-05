import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/sms_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dio_error_message.dart';

/// Crédits SMS : solde, analytics, forfaits et historique d’achats.
class SmsCreditsScreen extends ConsumerStatefulWidget {
  const SmsCreditsScreen({super.key});

  @override
  ConsumerState<SmsCreditsScreen> createState() => _SmsCreditsScreenState();
}

class _SmsCreditsScreenState extends ConsumerState<SmsCreditsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _balance;
  Map<String, dynamic>? _analytics;
  List<dynamic> _packs = [];
  List<dynamic> _purchases = [];
  String? _busyPackId;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _errMsg(Object e, {String fallback = 'Erreur'}) {
    if (e is DioException) {
      return dioErrorMessage(e, fallback: fallback);
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  String _fmtXof(dynamic v) => '${_fmt(v)} FCFA';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final canPurchase = ref.read(authProvider).isOwner;
      final results = await Future.wait([
        SmsApiService.balance(),
        SmsApiService.analytics(),
        SmsApiService.packs(),
        canPurchase
            ? SmsApiService.purchases()
            : Future<List<dynamic>>.value(const []),
      ]);
      _balance = Map<String, dynamic>.from(results[0] as Map);
      _analytics = Map<String, dynamic>.from(results[1] as Map);
      _packs = results[2] as List<dynamic>;
      _purchases = results[3] as List<dynamic>;
    } catch (e) {
      _balance = null;
      _analytics = null;
      _packs = [];
      _purchases = [];
      _error = _errMsg(e, fallback: 'Impossible de charger les données SMS');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchase(Map<String, dynamic> pack) async {
    final phoneCtrl = TextEditingController();
    final packId = pack['id']?.toString() ?? '';
    if (packId.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Acheter — ${pack['label'] ?? 'forfait'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_fmt(pack['credits'])} SMS · ${_fmtXof(pack['priceXof'])}',
              style: const TextStyle(color: textGrey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'N° Wave payeur *',
                hintText: '07 XX XX XX XX',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paiement Wave via le compte Mobile Money de l’école.',
              style: TextStyle(fontSize: 12, color: textGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Payer'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final phone = phoneCtrl.text.trim();
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro Wave obligatoire'),
          backgroundColor: dangerRed,
        ),
      );
      return;
    }

    setState(() => _busyPackId = packId);
    try {
      final res = await SmsApiService.purchase(
        packId: packId,
        payerPhone: phone,
      );
      if (!mounted) return;
      final simulated = res['simulated'] == true;
      final msg = res['message']?.toString().trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            simulated
                ? (msg?.isNotEmpty == true
                    ? msg!
                    : 'Simulation — aucun crédit SMS réel n’a été ajouté. '
                        'Configurez Wave école pour un achat réel.')
                : (msg?.isNotEmpty == true
                    ? msg!
                    : 'Paiement initié — finalisez sur Wave si demandé.'),
          ),
          backgroundColor: simulated ? warningYellow : primaryBlue,
        ),
      );
      if (!simulated) await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errMsg(e, fallback: 'Achat impossible — configurez Wave école.'),
          ),
          backgroundColor: dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyPackId = null);
    }
  }

  Widget _kpi(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: textGrey)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPurchase = ref.watch(authProvider).isOwner;
    final balFromAnalytics = _analytics?['balance'] is Map
        ? Map<String, dynamic>.from(_analytics!['balance'] as Map)
        : null;
    final remaining =
        _balance?['remaining'] ?? balFromAnalytics?['remaining'] ?? '—';
    final used = _balance?['used'] ??
        _balance?['totalUsed'] ??
        balFromAnalytics?['used'] ??
        '—';
    final purchased = _balance?['purchased'] ??
        _balance?['totalPurchased'] ??
        balFromAnalytics?['purchased'] ??
        '—';
    final totals = _analytics?['totals'] is Map
        ? Map<String, dynamic>.from(_analytics!['totals'] as Map)
        : null;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('SMS & crédits'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Card(
                      color: dangerLight,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: dangerRed),
                        ),
                      ),
                    ),
                  if (_error != null) const SizedBox(height: 12),

                  // ── Solde ────────────────────────────────────
                  Row(
                    children: [
                      _kpi('SMS restants', _fmt(remaining),
                          valueColor: successGreen),
                      const SizedBox(width: 8),
                      _kpi('SMS utilisés', _fmt(used),
                          valueColor: warningYellow),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _kpi('SMS achetés', _fmt(purchased),
                          valueColor: primaryBlue),
                      const SizedBox(width: 8),
                      _kpi(
                        'Aujourd’hui',
                        totals == null ? '—' : '${_fmt(totals['day'])} SMS',
                      ),
                    ],
                  ),

                  if (totals != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Consommation',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Semaine · ${_fmt(totals['week'])}  ·  '
                              'Mois · ${_fmt(totals['month'])}  ·  '
                              'Année · ${_fmt(totals['year'])}',
                              style: const TextStyle(
                                  fontSize: 13, color: textMedium),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ── Forfaits ─────────────────────────────────
                  const SizedBox(height: 16),
                  const Text(
                    'Forfaits SMS',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  if (!canPurchase)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, bottom: 8),
                      child: Text(
                        'Seul un administrateur / fondateur peut acheter.',
                        style: TextStyle(fontSize: 12, color: textGrey),
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                  if (_packs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Aucun forfait disponible',
                        style: TextStyle(color: textGrey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._packs.map((raw) {
                      final p = Map<String, dynamic>.from(raw as Map);
                      final id = p['id']?.toString() ?? '';
                      final busy = _busyPackId == id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            p['label']?.toString() ?? 'Forfait',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${_fmt(p['credits'])} SMS · ${_fmtXof(p['priceXof'])}',
                          ),
                          trailing: canPurchase
                              ? FilledButton(
                                  onPressed: busy || _busyPackId != null
                                      ? null
                                      : () => _purchase(p),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                  ),
                                  child: Text(busy ? '…' : 'Acheter'),
                                )
                              : null,
                        ),
                      );
                    }),

                  // ── Historique ───────────────────────────────
                  if (canPurchase) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Historique d’achats',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    if (_purchases.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Aucun achat',
                          style: TextStyle(color: textGrey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._purchases.map((raw) {
                        final p = Map<String, dynamic>.from(raw as Map);
                        final pack = p['pack'] is Map
                            ? Map<String, dynamic>.from(p['pack'] as Map)
                            : null;
                        final created = p['createdAt'] != null
                            ? DateTime.tryParse(p['createdAt'].toString())
                            : null;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              pack?['label']?.toString() ??
                                  '${p['credits'] ?? '—'} SMS',
                            ),
                            subtitle: Text(
                              [
                                p['status']?.toString() ?? '',
                                if (created != null) _dateFmt.format(created),
                              ].where((s) => s.isNotEmpty).join(' · '),
                            ),
                            trailing: Text(
                              _fmtXof(p['amountXof'] ?? 0),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textMedium,
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ],
              ),
            ),
    );
  }
}
