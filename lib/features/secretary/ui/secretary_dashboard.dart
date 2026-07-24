import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/students_api_service.dart';
import '../../grades/ui/bulletin_screen.dart';
import '../../settings/ui/settings_screen.dart';
import '../../student/ui/student_form_screen.dart';
import '../../enrollment/ui/enrollments_list_screen.dart';
import '../../student/ui/student_list_screen.dart';
import '../../../shared/widgets/workspace_hero.dart';

class SecretaryDashboard extends ConsumerStatefulWidget {
  const SecretaryDashboard({super.key});
  @override
  ConsumerState<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends ConsumerState<SecretaryDashboard> {
  int _totalStudents = 0, _totalClasses = 0, _totalTeachers = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await StudentsApiService.getStats();
      if (!mounted) {
        return;
      }
      setState(() {
        _totalStudents = (s['total'] as num?)?.toInt() ?? 0;
        _totalClasses = (s['totalClasses'] as num?)?.toInt() ?? 0;
        _totalTeachers = (s['totalTeachers'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Impossible de charger les statistiques. Vérifiez votre connexion.';
        });
      }
    }
  }

  Future<void> _openDocuments() async {
    if (ref.read(studentProvider).isEmpty) {
      await ref.read(studentProvider.notifier).load();
    }
    final students = ref.read(studentProvider);
    if (!mounted) return;
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun élève disponible')),
      );
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Bulletins & documents'),
        children: students
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s.id),
                  child: Text('${s.fullName} — ${s.className}'),
                ))
            .toList(),
      ),
    );
    if (selected == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BulletinScreen(studentId: selected, trimestre: 'T1'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    const color = Color(0xFF0D9488);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Secrétariat',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (auth.tenantName != null)
            Text(auth.tenantName!,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))),
          IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 20),
              onPressed: _loadStats),
          IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: () => ref.read(authProvider.notifier).logout()),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              color: Colors.red.shade800, fontSize: 13)),
                    ),
                    TextButton(
                        onPressed: _loadStats, child: const Text('Réessayer')),
                  ],
                ),
              ),
            WorkspaceHero(
              eyebrow: 'Secrétariat',
              title: 'Administration scolaire',
              subtitle: 'Inscriptions, dossiers et documents',
              color: color,
              loading: _loading,
              metrics: [
                WorkspaceHeroMetric(
                    label: 'Élèves', value: _totalStudents.toString()),
                WorkspaceHeroMetric(
                    label: 'Classes', value: _totalClasses.toString()),
                WorkspaceHeroMetric(
                    label: 'Enseignants', value: _totalTeachers.toString()),
              ],
            ),
            const SizedBox(height: 20),
            const WorkspaceSectionTitle('Actions principales'),
            _ActionTile(
                icon: Icons.person_add_outlined,
                title: 'Inscrire un élève',
                subtitle: 'Créer un nouveau dossier',
                color: primaryBlue,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StudentFormScreen()))),
            const SizedBox(height: 10),
            _ActionTile(
                icon: Icons.app_registration_outlined,
                title: 'Pré-inscriptions',
                subtitle: 'Demandes en attente de validation',
                color: warningYellow,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EnrollmentsListScreen()))),
            const SizedBox(height: 10),
            _ActionTile(
                icon: Icons.people_alt_outlined,
                title: 'Liste des élèves',
                subtitle: 'Gérer les dossiers scolaires',
                color: color,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StudentListScreen()))),
            const SizedBox(height: 10),
            _ActionTile(
                icon: Icons.description_outlined,
                title: 'Documents',
                subtitle: 'Bulletins et attestations',
                color: const Color(0xFF7C3AED),
                onTap: _openDocuments),
          ]),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(color: textGrey, fontSize: 12)),
              ])),
          Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }
}
