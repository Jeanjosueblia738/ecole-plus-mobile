import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../sms/ui/sms_credits_screen.dart';

/// Ancien historique local (stub) — redirige vers les crédits SMS API.
class SmsHistoryScreen extends StatelessWidget {
  const SmsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('SMS'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms_outlined, size: 48, color: primaryBlue),
            const SizedBox(height: 16),
            const Text(
              'L’historique SMS local n’est plus utilisé. '
              'Consultez le solde, les forfaits et les achats via l’API.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textGrey, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SmsCreditsScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Voir SMS & crédits'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
