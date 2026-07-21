import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/payment_gateway_service.dart';
import '../data/finance_model.dart';
import '../../student/data/student.dart';

class MobileMoneyScreen extends StatefulWidget {
  final Student student;
  final SchoolFee fee;

  const MobileMoneyScreen({
    super.key,
    required this.student,
    required this.fee,
  });

  @override
  State<MobileMoneyScreen> createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends State<MobileMoneyScreen> {
  MobileMoneyOperator _operator = MobileMoneyOperator.orangeMoney;
  final _phoneCtrl = TextEditingController();
  bool _isProcessing = false;
  String? _errorMsg;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Veuillez saisir le numéro');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMsg = null;
    });

    final result = await PaymentGatewayService.processMobileMoney(
      operator: _operator,
      phoneNumber: _phoneCtrl.text.trim(),
      montant: widget.fee.montant,
      reference: 'ECOLE-${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;

    // Aucun faux succès : on n'enregistre pas de paiement école
    // tant que la passerelle MM n'est pas intégrée.
    setState(() {
      _isProcessing = false;
      _errorMsg = result.errorMessage ??
          PaymentGatewayService.notAvailableMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final montantFormate =
        '${widget.fee.montant.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]} ")} FCFA';
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Paiement Mobile Money'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Résumé ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _SummaryRow('Élève', widget.student.fullName),
                  _SummaryRow('Classe', widget.student.className),
                  _SummaryRow('Frais', widget.fee.label),
                  _SummaryRow('Montant', montantFormate,
                      bold: true, color: successGreen),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Choix opérateur ───────────────────────────────────
            const Text('Opérateur',
                style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: MobileMoneyOperator.values
                  .map((op) => _OperatorChip(
                        operator: op,
                        selected: _operator == op,
                        onTap: () => setState(() => _operator = op),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 20),

            // ── Numéro téléphone ──────────────────────────────────
            Text('Numéro ${_operator.label}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '${_operator.prefix} XX XX XX XX',
                prefixText: '+225 ',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                errorText: _errorMsg,
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF92400E), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paiement Mobile Money non disponible pour le moment '
                      '(passerelle non intégrée). Aucun paiement ne sera '
                      'enregistré comme réel.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Bouton payer ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: successGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Transaction en cours...',
                              style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : Text(
                        'Payer $montantFormate',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _SummaryRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: textGrey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    color: color ?? textDark,
                    fontSize: bold ? 15 : 13)),
          ),
        ],
      ),
    );
  }
}

class _OperatorChip extends StatelessWidget {
  final MobileMoneyOperator operator;
  final bool selected;
  final VoidCallback onTap;

  const _OperatorChip({
    required this.operator,
    required this.selected,
    required this.onTap,
  });

  Color get _color => switch (operator) {
        MobileMoneyOperator.orangeMoney => const Color(0xFFFF6600),
        MobileMoneyOperator.wave => const Color(0xFF1BA8F5),
        MobileMoneyOperator.mtnMoney => const Color(0xFFFFCC00),
        MobileMoneyOperator.moov => const Color(0xFF0066CC),
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _color : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              operator.label,
              style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? _color : textDark,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
