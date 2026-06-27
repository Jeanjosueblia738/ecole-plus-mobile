import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/sms_store.dart';
import '../data/sms_record.dart';

class SmsHistoryScreen extends StatelessWidget {
  const SmsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SmsRecord> history = SmsStore.getRecords();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Historique des SMS'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'Aucun SMS envoyé',
                style: TextStyle(color: textGrey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sms = history[index];

                final Color statusColor =
                    sms.status == 'Envoyé' ? successGreen : dangerRed;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sms.recipient,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sms.message,
                        style: const TextStyle(color: textGrey),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sms.date.toLocal().toString().substring(0, 16),
                            style: const TextStyle(
                              fontSize: 12,
                              color: textGrey,
                            ),
                          ),
                          Text(
                            sms.status,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
