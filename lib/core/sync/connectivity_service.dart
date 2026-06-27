import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── État de connectivité ─────────────────────────────────────────────────
enum ConnectivityStatus { online, offline }

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  ConnectivityNotifier() : super(ConnectivityStatus.online) {
    _init();
  }

  Future<void> _init() async {
    // Vérifier l'état initial
    final results = await Connectivity().checkConnectivity();
    state = _fromResults(results);

    // Écouter les changements
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      state = _fromResults(results);
    });
  }

  ConnectivityStatus _fromResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  }

  bool get isOnline => state == ConnectivityStatus.online;
  bool get isOffline => state == ConnectivityStatus.offline;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─── Provider global ──────────────────────────────────────────────────────
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>(
  (ref) => ConnectivityNotifier(),
);

// Provider booléen simple pour les widgets
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider) == ConnectivityStatus.online;
});
