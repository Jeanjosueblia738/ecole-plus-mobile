import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/theme/app_colors.dart';
import 'join_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'ADMIN';
  bool _obscure = true;
  bool _useDemoMode = false;

  /// Tous les profils (API) — le mapping app se fait dans auth_provider.
  static const _roles = [
    {
      'value': 'ADMIN',
      'label': 'Administrateur',
      'icon': Icons.admin_panel_settings_rounded,
      'group': 'direction',
    },
    {
      'value': 'FOUNDER',
      'label': 'Fondateur',
      'icon': Icons.apartment_rounded,
      'group': 'direction',
    },
    {
      'value': 'DIRECTOR',
      'label': 'Directeur',
      'icon': Icons.account_balance_rounded,
      'group': 'direction',
    },
    {
      'value': 'CENSOR',
      'label': 'Censeur',
      'icon': Icons.menu_book_rounded,
      'group': 'staff',
    },
    {
      'value': 'SURVEILLANT',
      'label': 'Surveillant Général',
      'icon': Icons.security_rounded,
      'group': 'staff',
    },
    {
      'value': 'EDUCATOR',
      'label': 'Éducateur',
      'icon': Icons.groups_rounded,
      'group': 'staff',
    },
    {
      'value': 'SECRETARY',
      'label': 'Secrétaire',
      'icon': Icons.badge_outlined,
      'group': 'staff',
    },
    {
      'value': 'ACCOUNTANT',
      'label': 'Comptable',
      'icon': Icons.calculate_outlined,
      'group': 'staff',
    },
    {
      'value': 'CASHIER',
      'label': 'Caissier',
      'icon': Icons.point_of_sale_rounded,
      'group': 'staff',
    },
    {
      'value': 'TEACHER',
      'label': 'Enseignant',
      'icon': Icons.cast_for_education_rounded,
      'group': 'pedagogie',
    },
    {
      'value': 'PARENT',
      'label': 'Parent',
      'icon': Icons.family_restroom_rounded,
      'group': 'famille',
    },
    {
      'value': 'STUDENT',
      'label': 'Élève',
      'icon': Icons.school_rounded,
      'group': 'famille',
    },
  ];

  @override
  void dispose() {
    _codeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await ref.read(authProvider.notifier).login(
          tenantCode: _codeCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _selectedRole,
        );
  }

  Color _getRoleColor(String role) => switch (role) {
        'ADMIN' || 'FOUNDER' || 'DIRECTOR' => primaryBlue,
        'CENSOR' => const Color(0xFF0D9488),
        'SURVEILLANT' || 'EDUCATOR' => const Color(0xFFEA580C),
        'SECRETARY' => const Color(0xFF0891B2),
        'ACCOUNTANT' || 'CASHIER' => successGreen,
        'TEACHER' => const Color(0xFF7C3AED),
        'PARENT' => successGreen,
        'STUDENT' => const Color(0xFFF59E0B),
        _ => textGrey,
      };

  UserRole _toAppRole(String apiRole) => switch (apiRole) {
        'ADMIN' || 'FOUNDER' || 'DIRECTOR' => UserRole.admin,
        'CENSOR' => UserRole.censor,
        'SURVEILLANT' || 'EDUCATOR' => UserRole.surveillant,
        'SECRETARY' => UserRole.secretary,
        'ACCOUNTANT' || 'CASHIER' => UserRole.accountant,
        'TEACHER' => UserRole.teacher,
        'PARENT' => UserRole.parent,
        'STUDENT' => UserRole.student,
        _ => UserRole.admin,
      };

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: dangerRed,
          action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () => ref.read(authProvider.notifier).clearError()),
        ));
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: primaryGradient),
        child: SafeArea(
          child: Column(children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.school_rounded,
                      size: 44, color: Colors.white),
                ),
                const SizedBox(height: 14),
                const Text('ECOLE+',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('Plateforme Educative Intelligente',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13)),
              ]),
            ),

            // Formulaire
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Toggle mode demo / réel
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Connexion',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: textDark)),
                                Row(children: [
                                  const Text('Mode demo',
                                      style: TextStyle(
                                          fontSize: 12, color: textGrey)),
                                  Switch(
                                      value: _useDemoMode,
                                      onChanged: (v) =>
                                          setState(() => _useDemoMode = v),
                                      activeThumbColor: primaryBlue),
                                ]),
                              ]),
                          const SizedBox(height: 20),

                          if (_useDemoMode) ...[
                            const Text('Choisir un profil demo :',
                                style:
                                    TextStyle(color: textGrey, fontSize: 13)),
                            const SizedBox(height: 12),
                            ..._roles.map((r) => _DemoButton(
                                  icon: r['icon'] as IconData,
                                  label: r['label'] as String,
                                  color: _getRoleColor(r['value'] as String),
                                  onTap: () {
                                    ref
                                        .read(authProvider.notifier)
                                        .loginAs(_toAppRole(
                                            r['value'] as String));
                                  },
                                )),
                          ] else ...[
                            _Field(
                                controller: _codeCtrl,
                                label: 'Code établissement',
                                hint: 'ex: LYCEE-CI-001',
                                icon: Icons.business_outlined,
                                validator: (v) =>
                                    v!.isEmpty ? 'Obligatoire' : null),
                            const SizedBox(height: 14),
                            _Field(
                                controller: _emailCtrl,
                                label: 'Email',
                                hint: 'votre@email.ci',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => !v!.contains('@')
                                    ? 'Email invalide'
                                    : null),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              validator: (v) =>
                                  v!.length < 6 ? 'Min 6 caractères' : null,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: textGrey),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        const BorderSide(color: border)),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Sélecteur rôle — tout le personnel + famille
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Profil',
                                prefixIcon: const Icon(Icons.person_outline,
                                    color: textGrey),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        const BorderSide(color: border)),
                                isDense: true,
                              ),
                              items: _roles
                                  .map((r) => DropdownMenuItem(
                                        value: r['value'] as String,
                                        child: Text(
                                          r['label'] as String,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedRole = v!),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choisissez le profil correspondant à votre compte. '
                              'Personnel école : Admin, Censeur, Surveillant, Secrétaire, Comptable…',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 24),

                            // Bouton Se connecter
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Text('Se connecter',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Divider
                            Row(children: [
                              Expanded(
                                  child: Divider(color: Colors.grey.shade300)),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text('ou',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade500))),
                              Expanded(
                                  child: Divider(color: Colors.grey.shade300)),
                            ]),

                            const SizedBox(height: 16),

                            // Bouton Rejoindre avec un code
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const JoinScreen())),
                                icon: const Icon(Icons.qr_code_outlined,
                                    color: primaryBlue),
                                label: const Text('Rejoindre avec un code',
                                    style: TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: primaryBlue, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Parents et élèves : utilisez le code fourni par l\'école',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
                          const Center(
                            child: Text('Version 1.0.0 — ECOLE+ Côte d\'Ivoire',
                                style:
                                    TextStyle(color: textLight, fontSize: 11)),
                          ),
                        ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Widgets helpers ────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field(
      {required this.controller,
      required this.label,
      required this.hint,
      required this.icon,
      this.keyboardType,
      this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: textGrey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border)),
        isDense: true,
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DemoButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const Spacer(),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
          ]),
        ),
      ),
    );
  }
}
