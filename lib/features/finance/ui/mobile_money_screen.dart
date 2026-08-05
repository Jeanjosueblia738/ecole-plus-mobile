import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/services/finance_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../data/finance_model.dart';
import '../../student/data/student.dart';

/// Enregistrement staff d'un paiement Mobile Money déjà effectué
/// (aligné web : pas de passerelle live obligatoire).
class MobileMoneyScreen extends ConsumerStatefulWidget {
  final Student student;
  final SchoolFee fee;
  final double? remaining;
  final double? initialAmount;

  const MobileMoneyScreen({
    super.key,
    required this.student,
    required this.fee,
    this.remaining,
    this.initialAmount,
  });

  @override
  ConsumerState<MobileMoneyScreen> createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends ConsumerState<MobileMoneyScreen> {
  MobileMoneyOperator _operator = MobileMoneyOperator.orangeMoney;
  final _phoneCtrl = TextEditingController();
  final _txCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _isProcessing = false;
  bool _loadingRemaining = true;
  String? _errorMsg;
  double _remaining = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (widget.remaining != null) {
      _remaining = widget.remaining!;
      final initial = widget.initialAmount ?? _remaining;
      _amountCtrl.text =
          (initial > _remaining ? _remaining : initial).toStringAsFixed(0);
      setState(() => _loadingRemaining = false);
      return;
    }

    try {
      final data =
          await FinanceApiService.getStudentFinance(widget.student.id);
      final rows = (data['fees'] as List?) ?? [];
      double? remaining;
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row as Map);
        final feeInfo = map['fee'] is Map
            ? Map<String, dynamic>.from(map['fee'] as Map)
            : <String, dynamic>{};
        final id = feeInfo['id']?.toString() ??
            map['feeId']?.toString() ??
            '';
        if (id != widget.fee.id) continue;
        final amountXof = (feeInfo['amountXof'] as num?)?.toDouble() ??
            (map['amountXof'] as num?)?.toDouble() ??
            widget.fee.montant;
        final amountPaid = (map['amountPaid'] as num?)?.toDouble() ?? 0;
        remaining = (amountXof - amountPaid).clamp(0, double.infinity);
        break;
      }
      _remaining = remaining ?? widget.fee.montant;
    } catch (_) {
      _remaining = widget.fee.montant;
    }
    if (!mounted) return;
    final initial = widget.initialAmount ?? _remaining;
    _amountCtrl.text =
        (initial > _remaining ? _remaining : initial).toStringAsFixed(0);
    setState(() => _loadingRemaining = false);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _txCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  double? _parsedAmount() {
    final raw = _amountCtrl.text.replaceAll(RegExp(r'\s'), '');
    return double.tryParse(raw);
  }

  Future<void> _pay() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Veuillez saisir le numéro');
      return;
    }

    if (_remaining <= 0) {
      setState(() => _errorMsg = 'Ce frais est déjà soldé — rien à encaisser');
      return;
    }

    final amount = _parsedAmount();
    if (amount == null || amount <= 0) {
      setState(() => _errorMsg = 'Montant invalide');
      return;
    }
    if (amount > _remaining) {
      setState(() => _errorMsg =
          'Montant plafonné au reste dû (${_remaining.toStringAsFixed(0)} FCFA)');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMsg = null;
    });

    try {
      await ref.read(paymentProvider.notifier).addPayment(
            studentId: widget.student.id,
            studentName: widget.student.fullName,
            className: widget.student.className,
            feeId: widget.fee.id,
            feeLabel: widget.fee.label,
            montant: amount,
            method: PaymentMethod.mobileMoney,
            operatorName: _operator.label,
            phoneNumber: _phoneCtrl.text.trim(),
            transactionId: _txCtrl.text.trim().isEmpty
                ? null
                : _txCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement Mobile Money enregistré')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMsg = 'Échec enregistrement: $e';
      });
    }
  }

  String _fmt(double n) =>
      '${n.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} FCFA';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Paiement Mobile Money'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _loadingRemaining
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      'Enregistrement d’un paiement déjà effectué par Mobile Money (encaissement staff).',
                      style:
                          TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: primaryBlue.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        _SummaryRow('Élève', widget.student.fullName),
                        _SummaryRow('Classe', widget.student.className),
                        _SummaryRow('Frais', widget.fee.label),
                        _SummaryRow('Reste dû', _fmt(_remaining),
                            bold: true, color: successGreen),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    enabled: _remaining > 0,
                    decoration: InputDecoration(
                      labelText: 'Montant à enregistrer (FCFA)',
                      helperText:
                          'Paiement partiel autorisé, max. ${_fmt(_remaining)}',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      final v = _parsedAmount();
                      if (v != null && v > _remaining) {
                        _amountCtrl.text = _remaining.toStringAsFixed(0);
                        _amountCtrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: _amountCtrl.text.length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Opérateur',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: MobileMoneyOperator.values.map((op) {
                      final selected = _operator == op;
                      return ChoiceChip(
                        label: Text(op.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _operator = op),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro Mobile Money',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _txCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Réf. transaction (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMsg!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isProcessing || _remaining <= 0 ? null : _pay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: successGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isProcessing
                          ? 'Enregistrement…'
                          : 'Valider le paiement Mobile Money'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? color;
  const _SummaryRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textGrey, fontSize: 13)),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: color ?? textDark,
                fontSize: 13,
              )),
        ],
      ),
    );
  }
}
