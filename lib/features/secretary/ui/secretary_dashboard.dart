import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/students_api_service.dart';
import '../../grades/ui/bulletin_screen.dart';
import '../../settings/ui/settings_screen.dart';
import '../../student/ui/student_form_screen.dart';
import '../../student/ui/student_list_screen.dart';

class SecretaryDashboard extends ConsumerStatefulWidget {
  const SecretaryDashboard({super.key});
  @override
  ConsumerState<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends ConsumerState<SecretaryDashboard> {
  int _totalStudents = 0, _totalClasses = 0, _totalTeachers = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final s = await StudentsApiService.getStats()
          .catchError((_) async => <String, dynamic>{});
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
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openDocuments() async {
    final students = ref.read(studentProvider);
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
            _ProfileCard(
                name: auth.fullName,
                role: 'Secrétaire de scolarité',
                color: color),
            const SizedBox(height: 20),
            const Text('Administration',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),
            Row(children: [
              _KpiCard(
                  label: 'Élèves',
                  value: _totalStudents.toString(),
                  icon: Icons.people_alt_outlined,
                  color: primaryBlue,
                  loading: _loading),
              const SizedBox(width: 12),
              _KpiCard(
                  label: 'Classes',
                  value: _totalClasses.toString(),
                  icon: Icons.class_outlined,
                  color: color,
                  loading: _loading),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _KpiCard(
                  label: 'Enseignants',
                  value: _totalTeachers.toString(),
                  icon: Icons.school_outlined,
                  color: const Color(0xFF7C3AED),
                  loading: _loading),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ]),
            const SizedBox(height: 20),
            const Text('Actions rapides',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),
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

class _ProfileCard extends StatelessWidget {
  final String name, role;
  final Color color;
  const _ProfileCard(
      {required this.name, required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold))),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(role,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool loading;
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                loading
                    ? LinearProgressIndicator(
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.1))
                    : Text(value,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color),
                        overflow: TextOverflow.ellipsis),
                Text(label,
                    style: const TextStyle(fontSize: 10, color: textGrey)),
              ])),
        ]),
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
