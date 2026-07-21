import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/network/auth_session_bridge.dart';
import 'core/providers/attendance_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/class_provider.dart';
import 'core/providers/finance_provider.dart';
import 'core/providers/grade_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/parent_provider.dart';
import 'core/providers/student_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  AuthSessionBridge.onUnauthorized = () {
    container.read(authProvider.notifier).onUnauthorized();
    container.read(selectedChildIdProvider.notifier).state = null;
    container.invalidate(parentChildrenAsyncProvider);
    container.invalidate(parentChildAsyncProvider);
    container.invalidate(gradeProvider);
    container.invalidate(attendanceProvider);
    container.invalidate(studentProvider);
    container.invalidate(feeProvider);
    container.invalidate(paymentProvider);
  };

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
