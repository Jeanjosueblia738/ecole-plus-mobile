import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/timetable_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/grades/data/grade_model.dart';
import '../data/timetable_model.dart';

class TimetableSlotForm extends ConsumerStatefulWidget {
  final String className;
  final String? classId;
  final WeekDay initialDay;

  const TimetableSlotForm({
    super.key,
    required this.className,
    this.classId,
    required this.initialDay,
  });

  @override
  ConsumerState<TimetableSlotForm> createState() => _TimetableSlotFormState();
}

class _TimetableSlotFormState extends ConsumerState<TimetableSlotForm> {
  late WeekDay _day;
  TimeSlot _startSlot = kTeachingSlots.first;
  String _subject = kSubjects.first.name;
  final _teacherCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _day = widget.initialDay;
  }

  @override
  void dispose() {
    _teacherCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_teacherCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    // Calculer la fin = créneau suivant
    final slotIndex = kTeachingSlots.indexOf(_startSlot);
    final endTime = slotIndex < kTeachingSlots.length - 1
        ? kTeachingSlots[slotIndex + 1].start
        : _startSlot.end;

    final entry = TimetableEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      className: widget.className,
      day: _day,
      startTime: _startSlot.start,
      endTime: endTime,
      subject: _subject,
      teacherName: _teacherCtrl.text.trim(),
      room: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
    );

    final synced = await ref.read(timetableProvider.notifier).addEntry(
          entry,
          classId: widget.classId,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(synced
            ? 'Créneau enregistré'
            : 'Créneau enregistré localement (non synchronisé)'),
        backgroundColor:
            synced ? const Color(0xFF16A34A) : const Color(0xFFB45309),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              const Expanded(
                child: Text('Ajouter un créneau',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              Text(widget.className,
                  style: const TextStyle(
                      color: primaryBlue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          // Jour
          DropdownButtonFormField<WeekDay>(
            initialValue: _day,
            decoration: InputDecoration(
              labelText: 'Jour',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            items: WeekDay.values
                .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                .toList(),
            onChanged: (v) => setState(() => _day = v!),
          ),
          const SizedBox(height: 10),

          // Heure début
          DropdownButtonFormField<TimeSlot>(
            initialValue: _startSlot,
            decoration: InputDecoration(
              labelText: 'Heure de début',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            items: kTeachingSlots
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (v) => setState(() => _startSlot = v!),
          ),
          const SizedBox(height: 10),

          // Matière
          DropdownButtonFormField<String>(
            initialValue: _subject,
            decoration: InputDecoration(
              labelText: 'Matière',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            items: kSubjects
                .map(
                    (s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => _subject = v!),
          ),
          const SizedBox(height: 10),

          // Enseignant + Salle
          Row(children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _teacherCtrl,
                decoration: InputDecoration(
                  labelText: 'Enseignant',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _roomCtrl,
                decoration: InputDecoration(
                  labelText: 'Salle',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Ajouter le créneau',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
