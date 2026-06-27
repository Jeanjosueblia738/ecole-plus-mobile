import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'sms_record.dart';

class SmsStore {
  static const _storageKey = 'sms_history';
  static List<SmsRecord> _records = [];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data != null) {
      final List decoded = jsonDecode(data);
      _records = decoded.map((e) => SmsRecord.fromJson(e)).toList();
    }
  }

  static List<SmsRecord> getRecords() => List.unmodifiable(_records);

  static Future<void> add(SmsRecord record) async {
    _records.insert(0, record);
    await _save();
  }

  static Future<void> clear() async {
    _records.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_records.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
