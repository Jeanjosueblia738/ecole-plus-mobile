// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'profile_screen.dart';
import 'tenant_group_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Parametres'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TenantGroupSelector(),
            ),
            if (profile != null)
              InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: primaryBlue.withValues(alpha: 0.1),
                        child: Text(profile.initials,
                            style: const TextStyle(
                                color: primaryBlue,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textDark)),
                            Text(profile.email,
                                style: const TextStyle(
                                    color: textGrey, fontSize: 12)),
                            Text(profile.roleLabel,
                                style: const TextStyle(
                                    color: primaryBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: textGrey),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: const Text('NOTIFICATIONS',
                  style: TextStyle(
                      color: textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
            if (profile != null) ...[
              Container(
                color: Colors.white,
                child: SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: dangerRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event_busy_outlined,
                        color: dangerRed, size: 20),
                  ),
                  title: const Text('Absences',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Notifier lors une absence',
                      style: TextStyle(color: textGrey, fontSize: 12)),
                  value: profile.notifAbsence,
                  activeThumbColor: primaryBlue,
                  onChanged: (v) => ref
                      .read(profileProvider.notifier)
                      .updateNotifs(absence: v),
                ),
              ),
              Container(
                color: Colors.white,
                child: SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: infoBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grade_outlined,
                        color: infoBlue, size: 20),
                  ),
                  title: const Text('Notes',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Notifier a chaque note saisie',
                      style: TextStyle(color: textGrey, fontSize: 12)),
                  value: profile.notifNote,
                  activeThumbColor: primaryBlue,
                  onChanged: (v) =>
                      ref.read(profileProvider.notifier).updateNotifs(note: v),
                ),
              ),
              Container(
                color: Colors.white,
                child: SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined,
                        color: successGreen, size: 20),
                  ),
                  title: const Text('Paiements',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Confirmer les paiements recus',
                      style: TextStyle(color: textGrey, fontSize: 12)),
                  value: profile.notifPaiement,
                  activeThumbColor: primaryBlue,
                  onChanged: (v) => ref
                      .read(profileProvider.notifier)
                      .updateNotifs(paiement: v),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: const Text('APPLICATION',
                  style: TextStyle(
                      color: textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
            Container(
              color: Colors.white,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: primaryBlue, size: 20),
                ),
                title: const Text('Mon profil',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Modifier mes informations',
                    style: TextStyle(color: textGrey, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: textGrey),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
            ),
            Container(
              color: Colors.white,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.replay_outlined,
                      color: primaryBlue, size: 20),
                ),
                title: const Text('Revoir onboarding',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Relancer le tutoriel',
                    style: TextStyle(color: textGrey, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: textGrey),
                onTap: () async {
                  await ref.read(onboardingProvider.notifier).reset();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Onboarding reinitialise'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: const Text('A PROPOS',
                  style: TextStyle(
                      color: textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
            Container(
              color: Colors.white,
              child: const ListTile(
                leading: Icon(Icons.info_outline, color: textGrey, size: 20),
                title: Text('Version',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Text('1.0.0',
                    style: TextStyle(color: textGrey, fontSize: 13)),
              ),
            ),
            Container(
              color: Colors.white,
              child: const ListTile(
                leading:
                    Icon(Icons.business_outlined, color: textGrey, size: 20),
                title: Text('Editeur',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Text('ECOLE+ CI',
                    style: TextStyle(color: textGrey, fontSize: 13)),
              ),
            ),
            Container(
              color: Colors.white,
              child: const ListTile(
                leading:
                    Icon(Icons.location_on_outlined, color: textGrey, size: 20),
                title: Text('Pays',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Text('Cote d\'Ivoire',
                    style: TextStyle(color: textGrey, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: dangerRed),
                  label: const Text('Se deconnecter',
                      style: TextStyle(color: dangerRed)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: dangerRed),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
