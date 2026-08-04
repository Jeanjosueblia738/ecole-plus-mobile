import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

/// Ancien écran SMS local — remplacé par [MessagingScreen] (API).
/// Conservé pour ne pas casser d'imports ; affiche un état indisponible honnête.
class ParentMessagesScreen extends ConsumerWidget {
  const ParentMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Messagerie'),
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
              Icon(Icons.sms_failed_outlined, size: 64, color: Color(0xFF9CA3AF)),
              SizedBox(height: 12),
              Text(
                'Messagerie SMS indisponible',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Aucune passerelle SMS n\'est configurée. '
                'Utilisez la messagerie interne de l\'application.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textGrey, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
