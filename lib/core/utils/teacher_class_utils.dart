/// Helpers for teacher class payloads (`subjects[]` from `/teachers/my-classes`).
List<String> classSubjects(dynamic classData) {
  final subjects = classData is Map ? classData['subjects'] : null;
  if (subjects is! List) return const [];
  return subjects
      .map((s) => s?.toString() ?? '')
      .where((s) => s.isNotEmpty)
      .toList();
}

String? firstClassSubject(dynamic classData) {
  final list = classSubjects(classData);
  return list.isEmpty ? null : list.first;
}
