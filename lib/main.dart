import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/providers/student_provider.dart';
import 'core/providers/attendance_provider.dart';
import 'core/providers/grade_provider.dart';
import 'core/providers/class_provider.dart';
import 'core/providers/finance_provider.dart';
import 'core/sync/sync_service.dart';
import 'core/providers/notification_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Chargement depuis SharedPreferences (source de vérité principale)
  await Future.wait([
    container.read(studentProvider.notifier).load(),
    container.read(attendanceProvider.notifier).load(),
    container.read(gradeProvider.notifier).load(),
    container.read(classProvider.notifier).load(),
    container.read(feeProvider.notifier).load(),
    container.read(paymentProvider.notifier).load(),
  ]);

  // Initialisation notifications
  await NotificationService.instance.init();
  await container.read(notificationProvider.notifier).load();

  // Migration initiale vers SQLite en arrière-plan
  SyncService().syncAll();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EcolePlusApp(),
    ),
  );
}

