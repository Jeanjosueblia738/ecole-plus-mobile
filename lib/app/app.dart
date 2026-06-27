import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/sync/connectivity_service.dart';
import '../core/providers/sync_provider.dart';
import '../core/sync/sync_service.dart';
import '../features/splash/splash_screen.dart';

class EcolePlusApp extends ConsumerWidget {
  const EcolePlusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ECOLE+',
      theme: AppTheme.light, // ← Thème global centralisé
      builder: (context, child) => Column(
        children: [
          const _OfflineBannerInline(),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
      home: const SplashScreen(), // ← Point d'entrée : splash
    );
  }
}

// ─── Bandeau hors-ligne ────────────────────────────────────────────────────
class _OfflineBannerInline extends ConsumerWidget {
  const _OfflineBannerInline();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final syncState = ref.watch(syncProvider);

    if (isOnline && syncState.status == SyncStatus.idle) {
      return const SizedBox.shrink();
    }

    final Color bgColor = !isOnline
        ? const Color(0xFF6B7280)
        : switch (syncState.status) {
            SyncStatus.syncing => const Color(0xFF2563EB),
            SyncStatus.success => const Color(0xFF16A34A),
            SyncStatus.error => const Color(0xFFDC2626),
            SyncStatus.idle => const Color(0xFF16A34A),
          };

    final String message = !isOnline
        ? 'Mode hors-ligne — Données synchronisées à la reconnexion'
        : switch (syncState.status) {
            SyncStatus.syncing => 'Synchronisation en cours...',
            SyncStatus.success =>
              'Synchronisé — ${syncState.itemsSynced} élément${syncState.itemsSynced > 1 ? 's' : ''}',
            SyncStatus.error =>
              syncState.message ?? 'Erreur de synchronisation',
            SyncStatus.idle => 'Connecté',
          };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          if (!isOnline)
            const Icon(Icons.wifi_off, color: Colors.white, size: 16)
          else if (syncState.status == SyncStatus.syncing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          else
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          if (isOnline)
            GestureDetector(
              onTap: () => ref.read(syncProvider.notifier).syncNow(),
              child: const Icon(Icons.sync, color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }
}
