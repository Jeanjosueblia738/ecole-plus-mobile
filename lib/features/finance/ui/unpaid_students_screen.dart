import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/school_year.dart';
import '../../student/data/student.dart';
import '../data/finance_model.dart';
import 'payment_screen.dart';

class UnpaidStudentsScreen extends ConsumerStatefulWidget {
  const UnpaidStudentsScreen({super.key});

  @override
  ConsumerState<UnpaidStudentsScreen> createState() =>
      _UnpaidStudentsScreenState();
}

class _UnpaidStudentsScreenState extends ConsumerState<UnpaidStudentsScreen> {
  bool _loading = true;
  String? _error;

  String _fmt(double n) {
    final val = n.toInt();
    return '${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([
        ref.read(studentProvider.notifier).load(),
        ref.read(feeProvider.notifier).load(year: currentSchoolYear()),
        ref.read(paymentProvider.notifier).loadAll(year: currentSchoolYear()),
      ]);
      final feeErr = ref.read(feeProvider.notifier).error;
      final payErr = ref.read(paymentProvider.notifier).error;
      if (feeErr != null || payErr != null) {
        _error = [feeErr, payErr].whereType<String>().join(' · ');
      }
    } catch (e) {
      _error = 'Impossible de charger les impayés';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentProvider);
    final fees = ref.watch(feeProvider);
    final payments = ref.watch(paymentProvider);

    final totalDu =
        fees.where((f) => f.obligatoire).fold(0.0, (s, f) => s + f.montant);

    final unpaid = <MapEntry<Student, double>>[];
    for (final student in students) {
      final totalPaye = payments
          .where((p) =>
              p.studentId == student.id &&
              (p.status == PaymentStatus.valide ||
                  p.status == PaymentStatus.enAttente))
          .fold(0.0, (s, p) => s + p.montant);
      final solde = totalDu - totalPaye;
      if (solde > 0) {
        unpaid.add(MapEntry(student, solde));
      }
    }
    unpaid.sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Liste des impayés'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: dangerRed)),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : unpaid.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: successGreen),
                          SizedBox(height: 12),
                          Text('Tous les élèves sont à jour',
                              style:
                                  TextStyle(color: textGrey, fontSize: 15)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: unpaid.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final student = unpaid[index].key;
                        final solde = unpaid[index].value;
                        return InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PaymentScreen()),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: dangerRed.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      dangerRed.withValues(alpha: 0.1),
                                  child: Text(
                                    student.fullName.isNotEmpty
                                        ? student.fullName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: dangerRed,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(student.fullName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      Text(student.className,
                                          style: const TextStyle(
                                              color: textGrey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(_fmt(solde),
                                        style: const TextStyle(
                                            color: dangerRed,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    const Text('reste dû',
                                        style: TextStyle(
                                            color: textGrey, fontSize: 11)),
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
