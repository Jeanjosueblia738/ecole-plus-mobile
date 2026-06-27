import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/notification_model.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllRead(),
              child: const Text('Tout lire',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? const _EmptyNotifications()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notif = state.notifications[index];
                    return _NotificationCard(notif: notif);
                  },
                ),
    );
  }
}

// ── Carte notification ─────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final AppNotification notif;
  const _NotificationCard({required this.notif});

  Color get _typeColor => switch (notif.type) {
        NotificationType.absence => dangerRed,
        NotificationType.note => infoBlue,
        NotificationType.bulletin => const Color(0xFF7C3AED),
        NotificationType.paiement => successGreen,
        NotificationType.message => primaryBlue,
        NotificationType.justification => successGreen,
        NotificationType.general => textGrey,
      };

  @override
  Widget build(BuildContext context) {
    final isUnread = !notif.isRead;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread ? _typeColor.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? _typeColor.withValues(alpha: 0.3) : border,
          width: isUnread ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icône type ──────────────────────────────────────────
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                notif.type.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Contenu ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: TextStyle(
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                          color: textDark,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _typeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.body,
                  style: const TextStyle(
                      color: textGrey, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(notif.date),
                  style: const TextStyle(color: textLight, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ── État vide ──────────────────────────────────────────────────────────────
class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔔', style: TextStyle(fontSize: 56)),
          SizedBox(height: 12),
          Text('Aucune notification',
              style: TextStyle(
                  color: textGrey, fontSize: 16, fontWeight: FontWeight.w500)),
          SizedBox(height: 4),
          Text('Vous serez notifié des absences,\nnotes et paiements ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textLight, fontSize: 13)),
        ],
      ),
    );
  }
}
