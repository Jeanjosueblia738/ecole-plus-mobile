import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/services/finance_api_service.dart';
import '../../../core/theme/app_colors.dart';

class CashSessionScreen extends ConsumerStatefulWidget {
  const CashSessionScreen({super.key});

  @override
  ConsumerState<CashSessionScreen> createState() => _CashSessionScreenState();
}

class _CashSessionScreenState extends ConsumerState<CashSessionScreen> {
  Map<String, dynamic>? _current;
  List<dynamic> _sessions = [];
  List<dynamic> _accounts = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _bankAccountId;
  final _floatCtrl = TextEditingController(text: '0');
  final _countedCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();

  String _fmt(num n) {
    final v = n.toInt();
    return '${v.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} FCFA';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cur = await FinanceApiService.cashCurrent();
      final list = await FinanceApiService.cashSessions();
      List<dynamic> accounts = [];
      final role = ref.read(authProvider).role;
      if (role != UserRole.cashier) {
        accounts = await FinanceApiService.listBankAccounts().catchError((_) => []);
      }
      if (!mounted) return;
      setState(() {
        _current = cur;
        _sessions = list;
        _accounts = accounts;
        if (_bankAccountId == null && accounts.isNotEmpty) {
          _bankAccountId = (accounts.first as Map)['id']?.toString();
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Impossible de charger la caisse.';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _countedCtrl.dispose();
    _noteCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() => _busy = true);
    try {
      await FinanceApiService.cashOpen({
        'openingFloatXof': int.tryParse(_floatCtrl.text) ?? 0,
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec ouverture: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    final counted = int.tryParse(_countedCtrl.text);
    if (counted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez le montant compté')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final deposit = int.tryParse(_depositCtrl.text);
      await FinanceApiService.cashClose({
        'closingCountedXof': counted,
        if (_noteCtrl.text.trim().isNotEmpty)
          'varianceNote': _noteCtrl.text.trim(),
        if (deposit != null && deposit > 0) 'bankDepositXof': deposit,
        if (_bankAccountId != null && deposit != null && deposit > 0)
          'bankAccountId': _bankAccountId,
      });
      _countedCtrl.clear();
      _noteCtrl.clear();
      _depositCtrl.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec clôture: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Caisse'),
        backgroundColor: successGreen,
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!,
                          style: TextStyle(color: Colors.red.shade800)),
                    ),
                  if (_current != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: successGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: successGreen.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Session ouverte',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 8),
                          Text(
                              'Fond: ${_fmt(_current!['openingFloatXof'] ?? 0)}'),
                          Text(
                            'Depuis: ${_current!['openedAt']?.toString().substring(0, 16) ?? ''}',
                            style: const TextStyle(
                                fontSize: 12, color: textGrey),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _countedCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Montant compté (FCFA)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _noteCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Justification écart',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _depositCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Versement banque (optionnel)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (_accounts.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _bankAccountId,
                              items: _accounts.map((a) {
                                final m = Map<String, dynamic>.from(a as Map);
                                return DropdownMenuItem(
                                  value: m['id']?.toString(),
                                  child: Text(m['name']?.toString() ?? ''),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _bankAccountId = v),
                              decoration: const InputDecoration(
                                labelText: 'Compte bancaire',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _busy ? null : _close,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: dangerRed,
                                  foregroundColor: Colors.white),
                              child: Text(_busy ? '…' : 'Clôturer la caisse'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Aucune session ouverte',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _floatCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Fond d'ouverture (FCFA)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _busy ? null : _open,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: successGreen,
                                  foregroundColor: Colors.white),
                              child: Text(_busy ? '…' : 'Ouvrir la caisse'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('Historique',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ..._sessions.map((raw) {
                    final s = Map<String, dynamic>.from(raw as Map);
                    return Card(
                      child: ListTile(
                        title: Text(
                            '${s['status']} · ${_fmt(s['openingFloatXof'] ?? 0)}'),
                        subtitle: Text(
                          s['openedAt']?.toString().substring(0, 16) ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: s['varianceXof'] != null &&
                                (s['varianceXof'] as num) != 0
                            ? Text(_fmt(s['varianceXof']),
                                style: const TextStyle(
                                    color: warningYellow,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
