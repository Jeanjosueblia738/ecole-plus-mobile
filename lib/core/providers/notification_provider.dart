import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/data/notification_model.dart';
import '../../services/notification_service.dart';

// ─── État des notifications ────────────────────────────────────────────────
class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
  }) =>
      NotificationState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final history = await NotificationService.instance.getHistory();
    state = state.copyWith(notifications: history, isLoading: false);
  }

  Future<void> markAllRead() async {
    await NotificationService.instance.markAllRead();
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
  }

  // Ajouter une notification reçue et rafraîchir
  Future<void> addAndRefresh(AppNotification notif) async {
    final updated = [notif, ...state.notifications].take(50).toList();
    state = state.copyWith(notifications: updated);
  }
}

// ─── Provider global ──────────────────────────────────────────────────────
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);

// Provider badge — nombre non lus
final unreadNotifCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
