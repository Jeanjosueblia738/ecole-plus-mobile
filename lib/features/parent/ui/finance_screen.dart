import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_provider.dart';
import 'parent_payment_screen.dart';

/// Suivi financier parent — données live via ParentPaymentScreen / API.
class ParentFinanceScreen extends ConsumerWidget {
  const ParentFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(parentChildAsyncProvider);

    return childAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Impossible de charger l\'enfant')),
      ),
      data: (child) {
        if (child == null) {
          return const Scaffold(
            body: Center(child: Text('Aucun enfant lié')),
          );
        }
        return ParentPaymentScreen(
          studentId: child.id,
          studentName: child.fullName,
        );
      },
    );
  }
}
