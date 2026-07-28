import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/workspace_hero.dart';
import '../../absence/ui/absence_auth_screen.dart';
import '../../settings/ui/settings_screen.dart';
import '../../staff/ui/campus_qr_scan_screen.dart';
import '../../staff/ui/presence_alerts_screen.dart';
import '../../staff/ui/staff_presence_today_screen.dart';
import 'rh_hours_overview_screen.dart';

/// Dashboard RH — absences staff, présence, alertes, suivi heures (pas la caisse).
class RhDashboard extends ConsumerWidget {
  const RhDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ressources humaines',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (auth.tenantName != null)
              Text(
                auth.tenantName!,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF0E7490),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          WorkspaceHero(
            eyebrow: 'Personnel',
            title: auth.fullName.isNotEmpty ? auth.fullName : 'Espace RH',
            subtitle:
                'Absences, présence campus, alertes cours et suivi des heures.',
            color: const Color(0xFF0E7490),
            metrics: const [
              WorkspaceHeroMetric(label: 'Focus', value: 'RH'),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'GESTION RH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: textGrey,
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.event_busy_outlined,
            title: 'Autorisations d’absence',
            subtitle: 'Valider congés / absences du personnel',
            color: const Color(0xFFBE123C),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AbsenceAuthScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.badge_outlined,
            title: 'Pointage entrée',
            subtitle: 'QR campus · entrée / sortie',
            color: const Color(0xFF0F766E),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CampusQrScanScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.groups_outlined,
            title: 'Présence personnel',
            subtitle: 'Liste des pointages du jour',
            color: primaryBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StaffPresenceTodayScreen(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.warning_amber_outlined,
            title: 'Alertes jour J',
            subtitle: 'Cours non pointés · remplacements',
            color: Colors.orange.shade800,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PresenceAlertsScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.schedule_outlined,
            title: 'Suivi des heures',
            subtitle: 'Heures prévues / faites / manquées',
            color: const Color(0xFF4338CA),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RhHoursOverviewScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: textGrey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: textGrey),
            ],
          ),
        ),
      ),
    );
  }
}
