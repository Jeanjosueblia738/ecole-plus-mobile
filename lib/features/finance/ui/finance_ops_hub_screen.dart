import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/services/finance_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/school_year.dart';

/// Hub comptable : dépenses, fournisseurs, paie, budget, banque
class FinanceOpsHubScreen extends ConsumerStatefulWidget {
  const FinanceOpsHubScreen({super.key});

  @override
  ConsumerState<FinanceOpsHubScreen> createState() =>
      _FinanceOpsHubScreenState();
}

class _FinanceOpsHubScreenState extends ConsumerState<FinanceOpsHubScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final role = ref.read(authProvider).role;
      if (role != UserRole.accountant) {
        if (mounted) Navigator.of(context).maybePop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).role;
    if (role != UserRole.accountant) {
      return const Scaffold(
        body: Center(child: Text('Accès réservé au comptable')),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Pilotage financier'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(context, Icons.receipt_long, 'Dépenses', 'Enregistrer et consulter',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ExpensesScreen()))),
          _tile(context, Icons.storefront_outlined, 'Fournisseurs', 'Annuaire partenaires',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SuppliersScreen()))),
          _tile(context, Icons.payments_outlined, 'Paie', 'Bulletins et statut',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _PayrollScreen()))),
          _tile(context, Icons.pie_chart_outline, 'Budget', 'Prévisionnel vs réel',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _BudgetScreen()))),
          _tile(context, Icons.account_balance_outlined, 'Banque', 'Comptes, mouvements, rapprochement',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _BankScreen()))),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryBlue.withValues(alpha: 0.1),
          child: Icon(icon, color: primaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

String _fmt(num n) {
  final v = n.toInt();
  return '${v.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} FCFA';
}

class _ExpensesScreen extends StatefulWidget {
  const _ExpensesScreen();
  @override
  State<_ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<_ExpensesScreen> {
  List<dynamic> _rows = [];
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _rows = await FinanceApiService.listExpenses(year: currentSchoolYear());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _add() async {
    final cat = TextEditingController(text: 'Fournitures');
    final label = TextEditingController();
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle dépense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cat, decoration: const InputDecoration(labelText: 'Catégorie')),
            TextField(controller: label, decoration: const InputDecoration(labelText: 'Libellé')),
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok != true) return;
    await FinanceApiService.createExpense({
      'category': cat.text,
      'label': label.text,
      'amountXof': int.tryParse(amount.text) ?? 0,
      'year': currentSchoolYear(),
      'paymentMode': 'especes',
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dépenses'), backgroundColor: primaryBlue, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (_, i) {
                final r = Map<String, dynamic>.from(_rows[i] as Map);
                return ListTile(
                  title: Text(r['label']?.toString() ?? ''),
                  subtitle: Text('${r['category']} · ${r['paymentMode']}'),
                  trailing: Text(_fmt(r['amountXof'] ?? 0), style: const TextStyle(color: dangerRed, fontWeight: FontWeight.bold)),
                );
              },
            ),
    );
  }
}

class _SuppliersScreen extends StatefulWidget {
  const _SuppliersScreen();
  @override
  State<_SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<_SuppliersScreen> {
  List<dynamic> _rows = [];
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _rows = await FinanceApiService.listSuppliers();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fournisseur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom')),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Téléphone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    await FinanceApiService.createSupplier({
      'name': name.text.trim(),
      if (phone.text.trim().isNotEmpty) 'phone': phone.text.trim(),
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fournisseurs'), backgroundColor: primaryBlue, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (_, i) {
                final r = Map<String, dynamic>.from(_rows[i] as Map);
                return ListTile(
                  title: Text(r['name']?.toString() ?? ''),
                  subtitle: Text([r['category'], r['phone']].whereType<String>().where((s) => s.isNotEmpty).join(' · ')),
                );
              },
            ),
    );
  }
}

class _PayrollScreen extends StatefulWidget {
  const _PayrollScreen();
  @override
  State<_PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<_PayrollScreen> {
  List<dynamic> _rows = [];
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _rows = await FinanceApiService.listPayroll(year: currentSchoolYear());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final base = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle paie (1 bulletin)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Employé')),
            TextField(controller: base, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Salaire de base')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok != true) return;
    final month = DateTime.now().month;
    final year = currentSchoolYear();
    await FinanceApiService.createPayroll({
      'label': 'Paie $month/$year',
      'year': year,
      'month': month,
      'slips': [
        {'employeeName': name.text, 'baseSalaryXof': int.tryParse(base.text) ?? 0}
      ],
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paie'), backgroundColor: primaryBlue, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (_, i) {
                final r = Map<String, dynamic>.from(_rows[i] as Map);
                final slips = (r['slips'] as List?) ?? [];
                final total = slips.fold<num>(0, (s, x) => s + ((x as Map)['netXof'] as num? ?? 0));
                final id = r['id']?.toString() ?? '';
                final status = r['status']?.toString() ?? '';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(r['label']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                            Text(_fmt(total)),
                          ],
                        ),
                        Text('$status · ${slips.length} bulletin(s)', style: const TextStyle(fontSize: 12, color: textGrey)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (status == 'DRAFT')
                              TextButton(
                                onPressed: () async {
                                  await FinanceApiService.payrollStatus(id, 'VALIDATED');
                                  await _load();
                                },
                                child: const Text('Valider'),
                              ),
                            if (status != 'PAID')
                              TextButton(
                                onPressed: () async {
                                  await FinanceApiService.payrollStatus(id, 'PAID');
                                  await _load();
                                },
                                child: const Text('Marquer payé'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _BudgetScreen extends StatefulWidget {
  const _BudgetScreen();
  @override
  State<_BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<_BudgetScreen> {
  Map<String, dynamic>? _analysis;
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await FinanceApiService.listBudgets(year: currentSchoolYear());
      if (list.isNotEmpty) {
        final id = (list.first as Map)['id']?.toString();
        if (id != null) {
          _analysis = await FinanceApiService.budgetVsActual(id);
        }
      } else {
        _analysis = null;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _add() async {
    final cat = TextEditingController(text: 'Fonctionnement');
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cat, decoration: const InputDecoration(labelText: 'Catégorie')),
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant prévu')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok != true) return;
    final year = currentSchoolYear();
    await FinanceApiService.createBudget({
      'year': year,
      'label': 'Budget $year',
      'lines': [
        {'category': cat.text, 'label': cat.text, 'plannedXof': int.tryParse(amount.text) ?? 0}
      ],
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _analysis?['summary'] as Map?;
    return Scaffold(
      appBar: AppBar(title: const Text('Budget'), backgroundColor: primaryBlue, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : summary == null
              ? const Center(child: Text('Aucun budget'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Prévu: ${_fmt(summary['plannedTotal'] ?? 0)}'),
                    Text('Réel: ${_fmt(summary['actualTotal'] ?? 0)}', style: const TextStyle(color: dangerRed)),
                    Text('Écart: ${_fmt(summary['varianceTotal'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
    );
  }
}

class _BankScreen extends StatefulWidget {
  const _BankScreen();
  @override
  State<_BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<_BankScreen> {
  List<dynamic> _accounts = [];
  List<dynamic> _txs = [];
  String? _selected;
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _accounts = await FinanceApiService.listBankAccounts();
      _selected ??= _accounts.isNotEmpty ? (_accounts.first as Map)['id']?.toString() : null;
      if (_selected != null) {
        _txs = await FinanceApiService.listBankTransactions(_selected!);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _addAccount() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Compte bancaire'),
        content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    await FinanceApiService.createBankAccount({'name': name.text.trim()});
    await _load();
  }

  Future<void> _addTx() async {
    if (_selected == null) return;
    final label = TextEditingController();
    final amount = TextEditingController();
    var type = 'CREDIT';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Mouvement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(type),
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'CREDIT', child: Text('Crédit')),
                  DropdownMenuItem(value: 'DEBIT', child: Text('Débit')),
                ],
                onChanged: (v) => setLocal(() => type = v ?? 'CREDIT'),
              ),
              TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant')),
              TextField(controller: label, decoration: const InputDecoration(labelText: 'Libellé')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await FinanceApiService.createBankTransaction({
      'accountId': _selected,
      'type': type,
      'amountXof': int.tryParse(amount.text) ?? 0,
      'label': label.text,
    });
    await _load();
  }

  Future<void> _reconcile() async {
    if (_selected == null) return;
    final start = TextEditingController();
    final end = TextEditingController();
    final balance = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rapprochement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: start, decoration: const InputDecoration(labelText: 'Début (YYYY-MM-DD)')),
            TextField(controller: end, decoration: const InputDecoration(labelText: 'Fin (YYYY-MM-DD)')),
            TextField(controller: balance, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Solde relevé')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok != true) return;
    final unreconciled = _txs
        .where((t) => (t as Map)['isReconciled'] != true)
        .map((t) => (t as Map)['id']?.toString())
        .whereType<String>()
        .toList();
    await FinanceApiService.reconcileBank({
      'accountId': _selected,
      'periodStart': start.text,
      'periodEnd': end.text,
      'statementBalanceXof': int.tryParse(balance.text) ?? 0,
      'markReconciledIds': unreconciled,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapprochement enregistré')),
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banque'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addAccount),
          IconButton(icon: const Icon(Icons.swap_horiz), onPressed: _addTx),
          IconButton(icon: const Icon(Icons.fact_check_outlined), onPressed: _reconcile),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_accounts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_selected),
                      initialValue: _selected,
                      items: _accounts.map((a) {
                        final m = Map<String, dynamic>.from(a as Map);
                        return DropdownMenuItem(value: m['id']?.toString(), child: Text(m['name']?.toString() ?? ''));
                      }).toList(),
                      onChanged: (v) async {
                        setState(() => _selected = v);
                        if (v != null) {
                          _txs = await FinanceApiService.listBankTransactions(v);
                          setState(() {});
                        }
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _txs.length,
                    itemBuilder: (_, i) {
                      final t = Map<String, dynamic>.from(_txs[i] as Map);
                      final credit = t['type'] == 'CREDIT';
                      return ListTile(
                        title: Text(t['label']?.toString() ?? ''),
                        subtitle: Text('${t['type']}${t['isReconciled'] == true ? ' · rapproché' : ''}'),
                        trailing: Text(
                          '${credit ? '+' : '-'}${_fmt(t['amountXof'] ?? 0)}',
                          style: TextStyle(color: credit ? successGreen : dangerRed, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
