import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/teacher_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/teacher_class_utils.dart';
import '../../grades/ui/grade_input_screen.dart';
import 'attendance_input_screen.dart';
import 'teacher_class_detail_screen.dart';

class TeacherMyClassesScreen extends ConsumerStatefulWidget {
  const TeacherMyClassesScreen({super.key});

  @override
  ConsumerState<TeacherMyClassesScreen> createState() =>
      _TeacherMyClassesScreenState();
}

class _TeacherMyClassesScreenState
    extends ConsumerState<TeacherMyClassesScreen> {
  List<dynamic> _classes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await TeacherApiService.getMyClasses();
      if (mounted) {
        setState(() {
          _classes = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les classes';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Mes classes'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: dangerRed)),
                      TextButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _classes.isEmpty
                  ? const Center(
                      child: Text('Aucune classe assignée',
                          style: TextStyle(color: textGrey)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _classes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final c = _classes[index];
                        final id = c['id']?.toString() ?? '';
                        final name = c['name']?.toString() ?? 'Classe';
                        final level = c['level']?.toString() ?? '';
                        final subjects = classSubjects(c);
                        final firstSubject = firstClassSubject(c) ?? '';
                        return Card(
                          child: ListTile(
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (level.isNotEmpty) Text(level),
                                if (subjects.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: subjects
                                        .map((s) => Chip(
                                              label: Text(s,
                                                  style: const TextStyle(
                                                      fontSize: 11)),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              padding: EdgeInsets.zero,
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                            isThreeLine: subjects.isNotEmpty,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Appel',
                                  icon: const Icon(Icons.how_to_reg_outlined),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AttendanceInputScreen(
                                        classId: id,
                                        className: name,
                                        subject: firstSubject,
                                        duration: '55',
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Notes',
                                  icon: const Icon(Icons.grade_outlined),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GradeInputScreen(
                                        classId: id,
                                        className: name,
                                        trimestre: 'T1',
                                        initialSubject: firstSubject.isEmpty
                                            ? null
                                            : firstSubject,
                                      ),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeacherClassDetailScreen(
                                  className: name,
                                  classId: id,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
