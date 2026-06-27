import 'dart:convert';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/notifications/data/notification_model.dart';

// ─── Service de notifications ECOLE+ ─────────────────────────────────────
// Architecture :
//   1. flutter_local_notifications → notifications immédiates (toujours dispo)
//   2. firebase_messaging → push distantes (nécessite google-services.json)
//
// En mode simulation (sans Firebase configuré), seules les notifs locales
// fonctionnent — parfait pour la démo.

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  static const _storageKey = 'app_notifications';
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Initialisation ────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    // Config Android
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Config iOS
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotif.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotifTapped,
    );

    // Demander permissions Android 13+
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('✅ NotificationService initialisé');
  }

  void _onNotifTapped(NotificationResponse response) {
    debugPrint('📬 Notification tappée : ${response.payload}');
    // En prod : naviguer vers l'écran concerné selon le payload
  }

  // ── Afficher une notification locale ─────────────────────────────────
  Future<void> showLocal({
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.general,
  }) async {
    if (!_initialized) await init();

    final id = DateTime.now().millisecondsSinceEpoch % 100000;

    await _localNotif.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'ecole_plus_channel',
          'ECOLE+ Notifications',
          channelDescription: 'Notifications de l\'application ECOLE+',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF1E3A8A),
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ── Notif absence (déclenchée par l'enseignant lors de l'appel) ───────
  Future<AppNotification> notifyAbsence({
    required String studentName,
    required String subject,
    required String date,
    required String parentPhone,
  }) async {
    final notif = AppNotification.absence(
      studentName: studentName,
      subject: subject,
      date: date,
    );

    await showLocal(
      title: notif.title,
      body: notif.body,
      payload: jsonEncode({'type': 'absence', 'student': studentName}),
      type: NotificationType.absence,
    );

    await _save(notif);
    return notif;
  }

  // ── Notif nouvelle note ────────────────────────────────────────────────
  Future<AppNotification> notifyNote({
    required String subject,
    required String value,
    required String trimestre,
  }) async {
    final notif = AppNotification.note(
        subject: subject, value: value, trimestre: trimestre);
    await showLocal(
        title: notif.title, body: notif.body, type: NotificationType.note);
    await _save(notif);
    return notif;
  }

  // ── Notif paiement confirmé ────────────────────────────────────────────
  Future<AppNotification> notifyPaiement({
    required String feeLabel,
    required String montant,
    required String receiptNumber,
  }) async {
    final notif = AppNotification.paiement(
        feeLabel: feeLabel, montant: montant, receiptNumber: receiptNumber);
    await showLocal(
        title: notif.title, body: notif.body, type: NotificationType.paiement);
    await _save(notif);
    return notif;
  }

  // ── Notif justification ────────────────────────────────────────────────
  Future<AppNotification> notifyJustification({
    required String studentName,
    required String status,
  }) async {
    final notif =
        AppNotification.justification(studentName: studentName, status: status);
    await showLocal(
        title: notif.title,
        body: notif.body,
        type: NotificationType.justification);
    await _save(notif);
    return notif;
  }

  // ── Historique local ───────────────────────────────────────────────────
  Future<List<AppNotification>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((e) => AppNotification.fromJson(e)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> markAllRead() async {
    final history = await getHistory();
    final updated = history.map((n) => n.copyWith(isRead: true)).toList();
    await _saveAll(updated);
  }

  Future<void> _save(AppNotification notif) async {
    final history = await getHistory();
    history.insert(0, notif);
    // Garder max 50 notifications
    final trimmed = history.take(50).toList();
    await _saveAll(trimmed);
  }

  Future<void> _saveAll(List<AppNotification> notifs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(notifs.map((n) => n.toJson()).toList()));
  }
}
