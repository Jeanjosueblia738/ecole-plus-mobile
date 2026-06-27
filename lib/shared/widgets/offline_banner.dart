import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/connectivity_service.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/sync/sync_service.dart';
import '../../core/theme/app_colors.dart';

// ─── Bandeau hors-ligne affiché en haut de l'app ──────────────────────────
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final syncState = ref.watch(syncProvider);

    // Online + idle → rien à afficher
    if (isOnline && syncState.status == SyncStatus.idle) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: _bgColor(isOnline, syncState.status),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          _icon(isOnline, syncState.status),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _message(isOnline, syncState),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Bouton sync manuel si online
          if (isOnline && syncState.status == SyncStatus.idle)
            GestureDetector(
              onTap: () => ref.read(syncProvider.notifier).syncNow(),
              child: const Icon(Icons.sync, color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }

  Color _bgColor(bool isOnline, SyncStatus status) {
    if (!isOnline) return const Color(0xFF6B7280);
    return switch (status) {
      SyncStatus.syncing => const Color(0xFF2563EB),
      SyncStatus.success => const Color(0xFF16A34A),
      SyncStatus.error => const Color(0xFFDC2626),
      SyncStatus.idle => const Color(0xFF16A34A),
    };
  }

  Widget _icon(bool isOnline, SyncStatus status) {
    if (!isOnline) {
      return const Icon(Icons.wifi_off, color: Colors.white, size: 16);
    }
    return switch (status) {
      SyncStatus.syncing => const SizedBox(
          width: 14,
          height: 14,
          child:
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
      SyncStatus.success =>
        const Icon(Icons.check_circle, color: Colors.white, size: 16),
      SyncStatus.error =>
        const Icon(Icons.error_outline, color: Colors.white, size: 16),
      SyncStatus.idle =>
        const Icon(Icons.cloud_done, color: Colors.white, size: 16),
    };
  }

  String _message(bool isOnline, SyncState state) {
    if (!isOnline) {
      return 'Mode hors-ligne — Les données seront synchronisées à la reconnexion';
    }
    return switch (state.status) {
      SyncStatus.syncing => 'Synchronisation en cours...',
      SyncStatus.success =>
        'Synchronisé — ${state.itemsSynced} élément${state.itemsSynced > 1 ? 's' : ''}',
      SyncStatus.error => state.message ?? 'Erreur de synchronisation',
      SyncStatus.idle => 'Connecté',
    };
  }
}

// ─── Indicateur compact (coin supérieur droit) ────────────────────────────
class ConnectivityDot extends ConsumerWidget {
  const ConnectivityDot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: isOnline ? successGreen : dangerRed,
        shape: BoxShape.circle,
      ),
    );
  }
}
