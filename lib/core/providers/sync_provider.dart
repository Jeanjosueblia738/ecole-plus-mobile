import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/sync_service.dart';
import '../sync/connectivity_service.dart';

// ─── Provider service sync ────────────────────────────────────────────────
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

// ─── État de synchronisation ──────────────────────────────────────────────
class SyncState {
  final SyncStatus status;
  final String? message;
  final int itemsSynced;
  final DateTime? lastSync;

  const SyncState({
    this.status = SyncStatus.idle,
    this.message,
    this.itemsSynced = 0,
    this.lastSync,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? message,
    int? itemsSynced,
    DateTime? lastSync,
  }) =>
      SyncState(
        status: status ?? this.status,
        message: message ?? this.message,
        itemsSynced: itemsSynced ?? this.itemsSynced,
        lastSync: lastSync ?? this.lastSync,
      );

  bool get isSyncing => status == SyncStatus.syncing;
  bool get hasError => status == SyncStatus.error;
  bool get isSuccess => status == SyncStatus.success;
}

// ─── Notifier ─────────────────────────────────────────────────────────────
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;
  final Ref _ref;

  SyncNotifier(this._syncService, this._ref) : super(const SyncState()) {
    // Auto-sync au retour de connexion
    _ref.listen(connectivityProvider, (prev, next) {
      if (prev == ConnectivityStatus.offline &&
          next == ConnectivityStatus.online) {
        syncNow();
      }
    });
  }

  Future<void> syncNow() async {
    if (state.isSyncing) return;
    state = state.copyWith(status: SyncStatus.syncing);

    final result = await _syncService.syncAll();

    state = state.copyWith(
      status: result.status,
      message: result.message,
      itemsSynced: result.itemsSynced,
      lastSync: DateTime.now(),
    );

    // Retour à idle après 3 secondes
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      state = state.copyWith(status: SyncStatus.idle);
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncNotifier(syncService, ref);
});
