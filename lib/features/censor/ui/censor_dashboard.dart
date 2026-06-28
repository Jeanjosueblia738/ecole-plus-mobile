import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/students_api_service.dart';
import '../../../core/services/attendance_api_service.dart';
import '../../settings/ui/settings_screen.dart';
import '../../messaging/ui/messaging_screen.dart';

class CensorDashboard extends ConsumerStatefulWidget {
  const CensorDashboard({super.key});
  @override
  ConsumerState<CensorDashboard> createState() => _CensorDashboardState();
}

class _CensorDashboardState extends ConsumerState<CensorDashboard> {
  int _totalStudents = 0, _totalTeachers = 0, _totalClasses = 0;
  int _totalAbsences = 0, _pendingJustifications = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        StudentsApiService.getStats()
            .catchError((_) async => <String, dynamic>{}),
        AttendanceApiService.getStats()
            .catchError((_) async => <String, dynamic>{}),
      ]);
      if (!mounted) {
        return;
      }
      final s = results[0];
      final a = results[1];
      setState(() {
        _totalStudents = (s['total'] as num?)?.toInt() ?? 0;
        _totalTeachers = (s['totalTeachers'] as num?)?.toInt() ?? 0;
        _totalClasses = (s['totalClasses'] as num?)?.toInt() ?? 0;
        _totalAbsences = (a['totalAbsences'] as num?)?.toInt() ?? 0;
        _pendingJustifications = (a['unJustified'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Suivi pédagogique',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (auth.tenantName != null)
            Text(auth.tenantName!,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: const Color(0xFF4338CA),
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
            _buildProfileCard(
                auth.fullName, 'Censeur', const Color(0xFF4338CA)),
            const SizedBox(height: 20),
            const Text('Suivi pédagogique',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),
            Row(children: [
              _buildKpi('Élèves', _totalStudents.toString(),
                  Icons.people_alt_outlined, primaryBlue),
              const SizedBox(width: 12),
              _buildKpi('Enseignants', _totalTeachers.toString(),
                  Icons.school_outlined, const Color(0xFF7C3AED)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _buildKpi('Classes', _totalClasses.toString(),
                  Icons.class_outlined, const Color(0xFF0D9488)),
              const SizedBox(width: 12),
              _buildKpi('Absences', _totalAbsences.toString(),
                  Icons.event_busy_outlined, dangerRed),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _buildKpi('Justifications', _pendingJustifications.toString(),
                  Icons.pending_outlined, warningYellow),
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
            _buildAction(
                Icons.book_outlined,
                'Cahier de texte',
                'Registre pédagogique officiel',
                const Color(0xFF0D9488),
                () {}),
            const SizedBox(height: 10),
            _buildAction(Icons.grade_outlined, 'Notes & Bulletins',
                'Consulter les résultats', const Color(0xFF7C3AED), () {}),
            const SizedBox(height: 10),
            _buildAction(Icons.event_busy_outlined, 'Absences',
                'Suivi des présences', dangerRed, () {}),
            const SizedBox(height: 10),
            _buildAction(
                Icons.chat_outlined,
                'Messagerie',
                'Communication interne',
                const Color(0xFF1B3A6B),
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MessagingScreen()))),
          ]),
        ),
      ),
    );
  }

  Widget _buildKpi(String label, String value, IconData icon, Color color) =>
      Expanded(
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
                  _loading
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

  Widget _buildAction(IconData icon, String title, String subtitle, Color color,
          VoidCallback onTap) =>
      InkWell(
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

Widget _buildProfileCard(String name, String role, Color color) => Container(
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
