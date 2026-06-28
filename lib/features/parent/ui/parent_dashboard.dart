import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/parent_api_service.dart';
import '../../settings/ui/settings_screen.dart';
import 'parent_payment_screen.dart';
import 'parent_grades_screen.dart';
import '../../student/ui/attendance_history_screen.dart';
import '../../messaging/ui/messaging_screen.dart';

class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({super.key});

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
  Map<String, dynamic>? _child;
  Map<String, dynamic>? _grades;
  Map<String, dynamic>? _attendance;
  Map<String, dynamic>? _finance;
  bool _loading = true;
  String _trimestre = 'T1';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), _loadData);
  }

  Future<void> _loadData() async {
    if (!mounted) {
      return;
    }
    setState(() => _loading = true);
    try {
      final child = await ParentApiService.getMyChild()
          .timeout(const Duration(seconds: 15));
      if (!mounted) {
        return;
      }
      setState(() => _child = child);

      if (child['id'] != null) {
        final studentId = child['id'] as String;
        final results = await Future.wait([
          ParentApiService.getChildGrades(studentId, trimestre: _trimestre)
              .catchError((_) => <String, dynamic>{}),
          ParentApiService.getChildAttendance(studentId)
              .catchError((_) => <String, dynamic>{}),
          ParentApiService.getChildFinance(studentId)
              .catchError((_) => <String, dynamic>{}),
        ]);
        if (!mounted) {
          return;
        }
        setState(() {
          _grades = results[0] as Map<String, dynamic>?;
          _attendance = results[1] as Map<String, dynamic>?;
          _finance = results[2] as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      debugPrint('ECOLE+ parent: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.role != UserRole.parent) {
      return const Scaffold(body: Center(child: Text('Accès refusé')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Espace Parent',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (auth.tenantName != null)
            Text(auth.tenantName!,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: primaryBlue,
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
              onPressed: _loadData),
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
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Carte enfant
            if (_loading)
              Container(
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: CircularProgressIndicator()))
            else if (_child != null)
              _buildChildCard()
            else
              _buildNoChild(),

            if (_child != null) ...[
              const SizedBox(height: 16),

              // Sélecteur trimestre
              Row(children: [
                const Text('Trimestre :',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                ...['T1', 'T2', 'T3'].map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _trimestre = t);
                          _loadData();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: _trimestre == t ? primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _trimestre == t
                                    ? primaryBlue
                                    : Colors.grey.shade200),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _trimestre == t
                                      ? Colors.white
                                      : textGrey)),
                        ),
                      ),
                    )),
              ]),

              const SizedBox(height: 16),

              // Présences
              const Text('Présences',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark)),
              const SizedBox(height: 10),
              Row(children: [
                _KpiTile(
                    label: 'Absences',
                    value: (_attendance?['stats']?['absences'] ?? 0).toString(),
                    icon: Icons.event_busy_outlined,
                    color: dangerRed),
                const SizedBox(width: 10),
                _KpiTile(
                    label: 'Retards',
                    value: (_attendance?['stats']?['retards'] ?? 0).toString(),
                    icon: Icons.access_time_outlined,
                    color: warningYellow),
                const SizedBox(width: 10),
                _KpiTile(
                    label: 'Justifiées',
                    value:
                        (_attendance?['stats']?['justified'] ?? 0).toString(),
                    icon: Icons.check_circle_outline,
                    color: successGreen),
              ]),

              const SizedBox(height: 16),

              // Notes
              const Text('Notes',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark)),
              const SizedBox(height: 10),

              if (_grades?['moyenneGenerale'] != null) ...[
                _MoyenneCard(
                    moyenne: (_grades!['moyenneGenerale'] as num).toDouble()),
                const SizedBox(height: 10),
              ],

              if (_grades?['grades'] != null &&
                  (_grades!['grades'] as List).isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Column(
                    children: (_grades!['grades'] as List).map<Widget>((g) {
                      final val = (g['value'] as num).toDouble();
                      final isGood = val >= 10;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(g['subject'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text(g['evalType'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 11, color: textGrey)),
                              ])),
                          Text('${val.toStringAsFixed(1)}/20',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isGood ? successGreen : dangerRed)),
                        ]),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 16),

              // Bouton payer
              if ((_finance?['resume']?['solde'] ?? 0) > 0) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ParentPaymentScreen(
                                  studentId: _child!['id'] as String,
                                  studentName:
                                      '${_child!['firstName']} ${_child!['lastName']}',
                                ))).then((_) => _loadData()),
                    icon: const Icon(Icons.phone_android, size: 18),
                    label: const Text('Payer via Mobile Money'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Accès rapides
              const Text('Accès rapides',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark)),
              const SizedBox(height: 12),

              _NavTile(
                  icon: Icons.grade_outlined,
                  title: 'Notes & Bulletins',
                  subtitle: 'Consulter les notes et télécharger le bulletin',
                  color: infoBlue,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ParentGradesScreen()))),
              const SizedBox(height: 10),
              _NavTile(
                  icon: Icons.event_busy_outlined,
                  title: 'Absences & Justifications',
                  subtitle: 'Historique et soumission de justificatifs',
                  color: dangerRed,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AttendanceHistoryScreen(history: [])))),
              const SizedBox(height: 10),
              _NavTile(
                  icon: Icons.chat_outlined,
                  title: 'Messagerie',
                  subtitle: 'Contacter l\'école directement',
                  color: const Color(0xFF1B3A6B),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MessagingScreen()))),
            ],

            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildChildCard() {
    final name = '${_child!['firstName']} ${_child!['lastName']}';
    final className = _child!['class']?['name'] ?? '';
    final level = _child!['class']?['level'] ?? '';
    final photoUrl = _child!['photoUrl'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [primaryBlue, Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        CircleAvatar(
            radius: 30,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: photoUrl == null
                ? Text(name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold))
                : null),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text('$className — $level',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Matricule : ${_child!['registrationNo'] ?? '—'}',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ])),
        const Icon(Icons.school_outlined, color: Colors.white54, size: 32),
      ]),
    );
  }

  Widget _buildNoChild() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        const Icon(Icons.person_off_outlined, color: textGrey, size: 40),
        const SizedBox(height: 8),
        const Text('Aucun enfant lié à ce compte',
            style: TextStyle(color: textGrey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        const Text('Contactez l\'administration pour lier votre enfant',
            style: TextStyle(color: textGrey, fontSize: 12),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        TextButton(onPressed: _loadData, child: const Text('Actualiser')),
      ]),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────

class _KpiTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: textGrey),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _MoyenneCard extends StatelessWidget {
  final double moyenne;
  const _MoyenneCard({required this.moyenne});

  @override
  Widget build(BuildContext context) {
    final isGood = moyenne >= 10;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isGood
            ? successGreen.withValues(alpha: 0.08)
            : dangerRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isGood
                ? successGreen.withValues(alpha: 0.3)
                : dangerRed.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.school_outlined, color: isGood ? successGreen : dangerRed),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Moyenne générale : ${moyenne.toStringAsFixed(2)}/20',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isGood ? successGreen : dangerRed)),
          Text(
              isGood
                  ? 'Bon niveau — continuez ainsi !'
                  : 'Des efforts supplémentaires sont nécessaires',
              style: const TextStyle(fontSize: 12, color: textGrey)),
        ])),
      ]),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _NavTile(
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
          Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }
}
