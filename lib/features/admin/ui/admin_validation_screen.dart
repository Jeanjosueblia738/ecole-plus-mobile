import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Écran historique — **non branché aux dashboards**.
///
/// L'API expose `POST /attendance/:id/justify` mais pas de file
/// « pending validation » ni d'endpoint admin validate/refuse.
/// Réactiver seulement quand le backend supportera ce flux.
class AdminValidationScreen extends ConsumerWidget {
  const AdminValidationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final canValidate =
        auth.isDirection || auth.isSurveillant || auth.isCensor;
    if (!canValidate) {
      return const Scaffold(body: Center(child: Text('Accès refusé')));
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Justifications'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 48, color: textGrey),
              SizedBox(height: 12),
              Text(
                'Validation des justifications non disponible',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textDark),
              ),
              SizedBox(height: 8),
              Text(
                'Le serveur ne propose pas encore de file de validation '
                'admin. Les parents/élèves peuvent justifier une absence ; '
                'le traitement côté direction sera ajouté ultérieurement.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textGrey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
