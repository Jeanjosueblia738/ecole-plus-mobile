// ─── Types de notifications ECOLE+ ────────────────────────────────────────
enum NotificationType {
  absence,
  note,
  bulletin,
  paiement,
  message,
  justification,
  general,
}

extension NotificationTypeLabel on NotificationType {
  String get label => switch (this) {
        NotificationType.absence => 'Absence',
        NotificationType.note => 'Note',
        NotificationType.bulletin => 'Bulletin',
        NotificationType.paiement => 'Paiement',
        NotificationType.message => 'Message',
        NotificationType.justification => 'Justification',
        NotificationType.general => 'Information',
      };

  String get icon => switch (this) {
        NotificationType.absence => '🚨',
        NotificationType.note => '📝',
        NotificationType.bulletin => '📋',
        NotificationType.paiement => '💰',
        NotificationType.message => '💬',
        NotificationType.justification => '✅',
        NotificationType.general => 'ℹ️',
      };
}

// ─── Modèle notification ──────────────────────────────────────────────────
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime date;
  final bool isRead;
  final Map<String, String>? data; // données supplémentaires

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
    this.data,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        date: date,
        isRead: isRead ?? this.isRead,
        data: data,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'date': date.toIso8601String(),
        'isRead': isRead,
        'data': data,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        type: NotificationType.values.byName(json['type']),
        title: json['title'],
        body: json['body'],
        date: DateTime.parse(json['date']),
        isRead: json['isRead'] ?? false,
        data: json['data'] != null
            ? Map<String, String>.from(json['data'])
            : null,
      );

  // Factories pour les types courants ECOLE+
  factory AppNotification.absence({
    required String studentName,
    required String subject,
    required String date,
  }) =>
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: NotificationType.absence,
        title: '🚨 Absence signalée',
        body: '$studentName est absent(e) en $subject le $date.',
        date: DateTime.now(),
        data: {
          'studentName': studentName,
          'subject': subject,
          'date': date,
        },
      );

  factory AppNotification.note({
    required String subject,
    required String value,
    required String trimestre,
  }) =>
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: NotificationType.note,
        title: '📝 Nouvelle note disponible',
        body: 'Note en $subject : $value/20 ($trimestre trimestre)',
        date: DateTime.now(),
      );

  factory AppNotification.paiement({
    required String feeLabel,
    required String montant,
    required String receiptNumber,
  }) =>
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: NotificationType.paiement,
        title: '💰 Paiement confirmé',
        body: '$feeLabel — $montant\nReçu : $receiptNumber',
        date: DateTime.now(),
        data: {'receiptNumber': receiptNumber},
      );

  factory AppNotification.justification({
    required String studentName,
    required String status, // 'validée' | 'refusée'
  }) =>
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: NotificationType.justification,
        title: status == 'validée'
            ? '✅ Justification acceptée'
            : '❌ Justification refusée',
        body: 'La justification d\'absence de $studentName a été $status.',
        date: DateTime.now(),
      );
}
