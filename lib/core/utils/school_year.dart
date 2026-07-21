/// Année scolaire courante (ex. 2025-2026), basée sur la rentrée de septembre.
String currentSchoolYear([DateTime? now]) {
  final d = now ?? DateTime.now();
  final start = d.month >= 9 ? d.year : d.year - 1;
  return '$start-${start + 1}';
}
