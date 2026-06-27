class SmsRecord {
  final String recipient; // Parent
  final String message;
  final DateTime date;
  final String status; // Envoyé | Échoué

  SmsRecord({
    required this.recipient,
    required this.message,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'recipient': recipient,
        'message': message,
        'date': date.toIso8601String(),
        'status': status,
      };

  factory SmsRecord.fromJson(Map<String, dynamic> json) {
    return SmsRecord(
      recipient: json['recipient'],
      message: json['message'],
      date: DateTime.parse(json['date']),
      status: json['status'],
    );
  }
}
