import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/network/auth_session_bridge.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/class_provider.dart';
import 'core/providers/notification_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  AuthSessionBridge.onUnauthorized = () {
    container.read(authProvider.notifier).onUnauthorized();
  };

  // Classes locales encore en Prefs ; finance / élèves → API à la demande (après login)
  await container.read(classProvider.notifier).load();

  await NotificationService.instance.init();
  await container.read(notificationProvider.notifier).load();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EcolePlusApp(),
    ),
  );
}
