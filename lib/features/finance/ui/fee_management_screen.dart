import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/school_year.dart';
import '../data/finance_model.dart';

class FeeManagementScreen extends ConsumerStatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  ConsumerState<FeeManagementScreen> createState() =>
      _FeeManagementScreenState();
}

class _FeeManagementScreenState extends ConsumerState<FeeManagementScreen> {
  bool _loading = true;
  String? _feeError;

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _feeError = null;
    });
    await ref.read(feeProvider.notifier).load(year: currentSchoolYear());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _feeError = ref.read(feeProvider.notifier).error;
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final fees = ref.watch(feeProvider);
    final feeError = _feeError;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Configuration des frais'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: () => _showFeeForm(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : feeError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: dangerRed),
                        const SizedBox(height: 12),
                        Text(feeError,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: textGrey, fontSize: 15)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _reload,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : fees.isEmpty
                  ? const Center(
                      child: Text('Aucun frais configuré',
                          style: TextStyle(color: textGrey)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: fees.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final fee = fees[index];
                        return _FeeCard(
                          fee: fee,
                          onDelete: () async {
                            await ref
                                .read(feeProvider.notifier)
                                .remove(fee.id);
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
    );
  }

  void _showFeeForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FeeFormSheet(ref: ref),
    );
  }
}

class _FeeCard extends StatelessWidget {
  final SchoolFee fee;
  final VoidCallback onDelete;

  const _FeeCard({required this.fee, required this.onDelete});

  Color get _typeColor => switch (fee.typeKind) {
        FeeType.scolarite => primaryBlue,
        FeeType.inscription => infoBlue,
        FeeType.transport => successGreen,
        FeeType.cantine => const Color(0xFFF97316),
        FeeType.examen => const Color(0xFF7C3AED),
        FeeType.divers => textGrey,
      };

  @override
  Widget build(BuildContext context) {
    final echeance =
        '${fee.dateEcheance.day.toString().padLeft(2, '0')}/${fee.dateEcheance.month.toString().padLeft(2, '0')}/${fee.dateEcheance.year}';
    final isExpired = fee.dateEcheance.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _typeColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.monetization_on_outlined,
                color: _typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(fee.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(fee.type,
                          style: TextStyle(
                              color: _typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      fee.montantFormate,
                      style: const TextStyle(
                          color: successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text('• ${fee.trimestre}',
                        style: const TextStyle(color: textGrey, fontSize: 12)),
                    const Spacer(),
                    Text(
                      'Échéance : $echeance',
                      style: TextStyle(
                          color: isExpired ? dangerRed : textGrey,
                          fontSize: 11,
                          fontWeight:
                              isExpired ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: dangerRed, size: 20),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Supprimer ce frais ?'),
                content: Text('"${fee.label}" sera supprimé.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: dangerRed),
                    onPressed: () {
                      onDelete();
                      Navigator.pop(context);
                    },
                    child: const Text('Supprimer',
                        style: TextStyle(color: Colors.white)),
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

class _FeeFormSheet extends StatefulWidget {
  final WidgetRef ref;
  const _FeeFormSheet({required this.ref});

  @override
  State<_FeeFormSheet> createState() => _FeeFormSheetState();
}

class _FeeFormSheetState extends State<_FeeFormSheet> {
  final _labelCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _typeCtrl = TextEditingController(text: 'Scolarité');
  String _trimestre = 'T1';
  final String _schoolYear = currentSchoolYear();
  bool _obligatoire = true;
  final DateTime _echeance = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _labelCtrl.dispose();
    _montantCtrl.dispose();
    _typeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_labelCtrl.text.trim().isEmpty ||
        _montantCtrl.text.trim().isEmpty ||
        _typeCtrl.text.trim().isEmpty) {
      return;
    }

    final montant = double.tryParse(_montantCtrl.text.replaceAll(' ', ''));
    if (montant == null) {
      return;
    }

    try {
      await widget.ref.read(feeProvider.notifier).add(SchoolFee(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: _typeCtrl.text.trim(),
            label: _labelCtrl.text.trim(),
            montant: montant,
            trimestre: _trimestre,
            obligatoire: _obligatoire,
            dateEcheance: _echeance,
          ));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: dangerRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ajouter un frais',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Année scolaire : $_schoolYear',
              style: const TextStyle(fontSize: 13, color: textGrey)),
          const SizedBox(height: 14),
          TextField(
            controller: _labelCtrl,
            decoration: InputDecoration(
              labelText: 'Libellé du frais',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _typeCtrl,
            decoration: InputDecoration(
              labelText: 'Type de frais',
              hintText: 'Scolarité, Transport, Cantine…',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _montantCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant (FCFA)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _trimestre,
                decoration: InputDecoration(
                  labelText: 'Trimestre',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                items: ['T1', 'T2', 'T3', 'Annuel']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _trimestre = v!),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Obligatoire', style: TextStyle(fontSize: 13)),
              Switch(
                value: _obligatoire,
                onChanged: (v) => setState(() => _obligatoire = v),
                activeThumbColor: primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Ajouter',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
