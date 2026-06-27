import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/ui/sms_history_screen.dart';
import '../../notifications/data/sms_store.dart';
import '../../notifications/data/sms_record.dart';

class ParentMessagesScreen extends ConsumerWidget {
  const ParentMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = SmsStore.getRecords();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Messagerie'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique SMS',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SmsHistoryScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Résumé notifications ───────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: primaryBlue.withValues(alpha: 0.05),
            child: Row(
              children: [
                _NotifStat(
                  label: 'Total',
                  value: messages.length,
                  color: primaryBlue,
                ),
                const SizedBox(width: 16),
                _NotifStat(
                  label: 'Envoyés',
                  value: messages.where((m) => m.status == 'Envoyé').length,
                  color: successGreen,
                ),
                const SizedBox(width: 16),
                _NotifStat(
                  label: 'Échec',
                  value: messages.where((m) => m.status == 'Échec').length,
                  color: dangerRed,
                ),
              ],
            ),
          ),

          // ── Liste messages ─────────────────────────────────────
          Expanded(
            child: messages.isEmpty
                ? const _EmptyMessages()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      // Afficher du plus récent au plus ancien
                      final msg = messages.reversed.toList()[index];
                      return _MessageCard(record: msg);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Stat notification ──────────────────────────────────────────────────────
class _NotifStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _NotifStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value.toString(),
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: textGrey)),
      ],
    );
  }
}

// ── Carte message ──────────────────────────────────────────────────────────
class _MessageCard extends StatelessWidget {
  final SmsRecord record;
  const _MessageCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isSuccess = record.status == 'Envoyé';
    final statusColor = isSuccess ? successGreen : dangerRed;

    // Déterminer l'icône selon le contenu du message
    final icon = record.message.contains('absence')
        ? Icons.event_busy_outlined
        : record.message.contains('note') || record.message.contains('bulletin')
            ? Icons.grade_outlined
            : Icons.notifications_outlined;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),

          // Contenu
          Expanded(
            child: _MessageContent(
              message: record.message,
              date: record.date,
              status: record.status,
              statusColor: statusColor,
              formatDate: _formatDate,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ── Contenu message (extrait pour const-eligibility) ─────────────────────
class _MessageContent extends StatelessWidget {
  final String message;
  final DateTime date;
  final String status;
  final Color statusColor;
  final String Function(DateTime) formatDate;

  const _MessageContent({
    required this.message,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: const TextStyle(fontSize: 13, color: textDark),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.access_time, size: 12, color: textGrey),
            const SizedBox(width: 4),
            Text(formatDate(date),
                style: const TextStyle(fontSize: 11, color: textGrey)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── État vide ──────────────────────────────────────────────────────────────
class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Color(0xFF9CA3AF)),
          SizedBox(height: 12),
          Text('Aucun message reçu',
              style: TextStyle(color: textGrey, fontSize: 15)),
          SizedBox(height: 4),
          Text(
            'Les notifications de l\'école apparaîtront ici',
            style: TextStyle(color: textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
