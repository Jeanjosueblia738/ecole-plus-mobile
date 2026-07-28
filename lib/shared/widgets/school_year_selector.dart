import 'package:flutter/material.dart';
import '../../core/services/academic_year_api_service.dart';
import '../../core/utils/school_year.dart';

/// Sélecteur d'année scolaire (staff) — sync prefs + liste API.
class SchoolYearSelector extends StatefulWidget {
  const SchoolYearSelector({
    super.key,
    this.compact = true,
    this.onChanged,
  });

  final bool compact;
  final ValueChanged<String>? onChanged;

  @override
  State<SchoolYearSelector> createState() => _SchoolYearSelectorState();
}

class _SchoolYearSelectorState extends State<SchoolYearSelector> {
  List<Map<String, dynamic>> _years = [];
  String? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await syncSchoolYearFromServer();
      final list = await AcademicYearApiService.getAll();
      final years =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final labels = years
          .map((y) => y['label'] as String?)
          .whereType<String>()
          .toList();
      var selected = currentSchoolYear();
      if (labels.isNotEmpty && !labels.contains(selected)) {
        Map<String, dynamic>? current;
        for (final y in years) {
          if (y['isCurrent'] == true) {
            current = y;
            break;
          }
        }
        current ??= years.first;
        final label = current['label'] as String?;
        if (label != null) {
          await setSelectedSchoolYear(label);
          selected = label;
        }
      }
      if (!mounted) return;
      setState(() {
        _years = years;
        _selected = selected;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selected = currentSchoolYear();
        _loading = false;
      });
    }
  }

  Future<void> _onChange(String? label) async {
    if (label == null) return;
    await setSelectedSchoolYear(label);
    setState(() => _selected = label);
    widget.onChanged?.call(label);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _years.isEmpty) {
      return widget.compact
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const LinearProgressIndicator();
    }
    if (_years.isEmpty) {
      return Text(
        _selected ?? currentSchoolYear(),
        style: TextStyle(
          color: widget.compact ? Colors.white : null,
          fontSize: widget.compact ? 13 : 14,
        ),
      );
    }

    final dropdown = DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selected != null &&
                _years.any((y) => y['label'] == _selected)
            ? _selected
            : (_years.first['label'] as String?),
        dropdownColor: Colors.white,
        iconEnabledColor: widget.compact ? Colors.white : null,
        style: TextStyle(
          color: widget.compact ? Colors.white : Colors.black87,
          fontSize: 13,
        ),
        items: _years
            .map(
              (y) => DropdownMenuItem(
                value: y['label'] as String,
                child: Text(
                  '${y['label']}${y['isCurrent'] == true ? ' •' : ''}'
                  '${y['status'] == 'ARCHIVED' ? ' (arch.)' : ''}',
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            )
            .toList(),
        onChanged: _onChange,
      ),
    );

    if (widget.compact) return dropdown;

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Année scolaire',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      child: dropdown,
    );
  }
}
