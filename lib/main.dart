import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/providers/class_provider.dart';
import 'core/providers/finance_provider.dart';
import 'core/providers/notification_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Classes locales encore en Prefs ; finance / élèves → API à la demande
  await Future.wait([
    container.read(classProvider.notifier).load(),
    container.read(feeProvider.notifier).load(),
  ]);

  await NotificationService.instance.init();
  await container.read(notificationProvider.notifier).load();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EcolePlusApp(),
    ),
  );
}
