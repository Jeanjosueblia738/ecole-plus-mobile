import 'package:flutter/material.dart';

// ─── Jours de la semaine (système CI : Lun→Sam) ───────────────────────────
enum WeekDay { lundi, mardi, mercredi, jeudi, vendredi, samedi }

extension WeekDayLabel on WeekDay {
  String get label => switch (this) {
        WeekDay.lundi => 'Lundi',
        WeekDay.mardi => 'Mardi',
        WeekDay.mercredi => 'Mercredi',
        WeekDay.jeudi => 'Jeudi',
        WeekDay.vendredi => 'Vendredi',
        WeekDay.samedi => 'Samedi',
      };

  String get short => switch (this) {
        WeekDay.lundi => 'Lun',
        WeekDay.mardi => 'Mar',
        WeekDay.mercredi => 'Mer',
        WeekDay.jeudi => 'Jeu',
        WeekDay.vendredi => 'Ven',
        WeekDay.samedi => 'Sam',
      };
}

// ─── Créneaux horaires standard CI ────────────────────────────────────────
class TimeSlot {
  final String start; // "08:00"
  final String end; // "09:00"

  const TimeSlot(this.start, this.end);

  String get label => '$start - $end';
}

const kTimeSlots = [
  TimeSlot('07:30', '08:25'),
  TimeSlot('08:25', '09:20'),
  TimeSlot('09:20', '10:15'),
  TimeSlot('10:15', '10:30'), // Récréation
  TimeSlot('10:30', '11:25'),
  TimeSlot('11:25', '12:20'),
  TimeSlot('12:20', '13:15'), // Pause déjeuner
  TimeSlot('13:15', '14:10'),
  TimeSlot('14:10', '15:05'),
  TimeSlot('15:05', '16:00'),
  TimeSlot('16:00', '16:15'), // Récréation
  TimeSlot('16:15', '17:10'),
  TimeSlot('17:10', '18:05'),
];

// Créneaux sans pauses (pour la saisie)
const kTeachingSlots = [
  TimeSlot('07:30', '08:25'),
  TimeSlot('08:25', '09:20'),
  TimeSlot('09:20', '10:15'),
  TimeSlot('10:30', '11:25'),
  TimeSlot('11:25', '12:20'),
  TimeSlot('13:15', '14:10'),
  TimeSlot('14:10', '15:05'),
  TimeSlot('15:05', '16:00'),
  TimeSlot('16:15', '17:10'),
  TimeSlot('17:10', '18:05'),
];

// ─── Créneau EDT ──────────────────────────────────────────────────────────
class TimetableEntry {
  final String id;
  final String className;
  final WeekDay day;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacherName;
  final String? room;

  const TimetableEntry({
    required this.id,
    required this.className,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacherName,
    this.room,
  });

  // Couleur par matière (identique entre tous les rôles)
  Color get color => switch (subject) {
        'Mathématiques' => const Color(0xFF1E3A8A),
        'Français' => const Color(0xFF7C3AED),
        'Anglais' => const Color(0xFF059669),
        'SVT' => const Color(0xFF16A34A),
        'Physique-Chimie' => const Color(0xFFDC2626),
        'Histoire-Géographie' => const Color(0xFFF59E0B),
        'Philosophie' => const Color(0xFF0891B2),
        'EPS' => const Color(0xFFEA580C),
        'Arts' => const Color(0xFFDB2777),
        _ => const Color(0xFF6B7280),
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'className': className,
        'day': day.name,
        'startTime': startTime,
        'endTime': endTime,
        'subject': subject,
        'teacherName': teacherName,
        'room': room,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        id: json['id'],
        className: json['className'],
        day: WeekDay.values.byName(json['day']),
        startTime: json['startTime'],
        endTime: json['endTime'],
        subject: json['subject'],
        teacherName: json['teacherName'],
        room: json['room'],
      );
}
