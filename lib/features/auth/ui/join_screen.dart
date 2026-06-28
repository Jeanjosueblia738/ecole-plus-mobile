import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/services/auth_storage_service.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  // Étapes : 1=choix type, 2=saisie code, 3=aperçu + mot de passe, 4=succès
  int _step = 1;
  String _type = 'parent'; // 'student' ou 'parent'
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _preview; // données retournées par validate-code

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    if (_codeCtrl.text.trim().length < 6) {
      setState(() => _error = 'Le code doit contenir au moins 6 caractères');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await ApiClient.instance.post('/auth/validate-code', data: {
        'accessCode': _codeCtrl.text.trim().toUpperCase(),
        'type': _type,
      });
      if (!mounted) {
        return;
      }
      setState(() {
        _preview = response.data as Map<String, dynamic>;
        _step = 3;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('invalide')
            ? 'Code invalide. Vérifiez le code fourni par votre établissement.'
            : e.toString().contains('déjà')
                ? 'Ce code a déjà été utilisé. Connectez-vous à la place.'
                : 'Erreur de connexion. Réessayez.';
        _loading = false;
      });
    }
  }

  Future<void> _createAccount() async {
    if (_passwordCtrl.text.length < 8) {
      setState(
          () => _error = 'Le mot de passe doit contenir au moins 8 caractères');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.post('/auth/join', data: {
        'accessCode': _codeCtrl.text.trim().toUpperCase(),
        'password': _passwordCtrl.text,
        'type': _type,
      });
      if (!mounted) {
        return;
      }

      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      final user = data['user'] as Map<String, dynamic>;
      final tenant = data['tenant'] as Map<String, dynamic>;

      // Sauvegarder le token
      await AuthStorageService.saveAuthData(
        token: token,
        tenantCode: tenant['code'] as String,
        tenantName: tenant['name'] as String,
        role: user['role'] as String,
        email: user['email'] as String,
        userId: user['id'] as String,
      );
      await AuthStorageService.write(
          'first_name', user['firstName'] as String? ?? '');
      await AuthStorageService.write(
          'last_name', user['lastName'] as String? ?? '');
      if (user['className'] != null) {
        await AuthStorageService.write(
            'class_name', user['className'] as String);
      }

      // Mettre à jour le state auth
      final role = user['role'] as String;
      if (!mounted) {
        return;
      }
      ref.read(authProvider.notifier).loginAs(
            role == 'STUDENT' ? UserRole.student : UserRole.parent,
          );

      setState(() => _step = 4);
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la création du compte. Réessayez.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Rejoindre ECOLE+',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        leading: _step > 1 && _step < 4
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _step--;
                  _error = null;
                }),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Indicateur d'étapes
          if (_step < 4) ...[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (int i = 1; i <= 3; i++) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _step >= i ? primaryBlue : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text('$i',
                          style: TextStyle(
                              color: _step >= i ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13))),
                ),
                if (i < 3)
                  Container(
                      width: 40,
                      height: 2,
                      color: _step > i ? primaryBlue : Colors.grey.shade200),
              ],
            ]),
            const SizedBox(height: 8),
            Text(
              _step == 1
                  ? 'Choisissez votre profil'
                  : _step == 2
                      ? 'Entrez votre code'
                      : 'Créez votre mot de passe',
              style: const TextStyle(fontSize: 13, color: textGrey),
            ),
            const SizedBox(height: 24),
          ],

          // Erreur
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dangerRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: dangerRed.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: dangerRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style:
                            const TextStyle(color: dangerRed, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ── Étape 1 — Choix type ────────────────────────────────────
          if (_step == 1) ...[
            const Text('Je suis...',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choisissez votre profil pour continuer',
                style: TextStyle(fontSize: 13, color: textGrey),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            _TypeCard(
              icon: Icons.family_restroom_outlined,
              title: 'Parent d\'élève',
              subtitle:
                  'Suivez les résultats, absences et paiements de votre enfant',
              color: primaryBlue,
              selected: _type == 'parent',
              onTap: () => setState(() => _type = 'parent'),
            ),
            const SizedBox(height: 16),
            _TypeCard(
              icon: Icons.school_outlined,
              title: 'Élève',
              subtitle: 'Consultez vos notes, emploi du temps et devoirs',
              color: const Color(0xFF7C3AED),
              selected: _type == 'student',
              onTap: () => setState(() => _type = 'student'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _step = 2;
                  _error = null;
                }),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Continuer',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          // ── Étape 2 — Saisie code ───────────────────────────────────
          if (_step == 2) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    (_type == 'parent' ? primaryBlue : const Color(0xFF7C3AED))
                        .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(
                    _type == 'parent'
                        ? Icons.family_restroom_outlined
                        : Icons.school_outlined,
                    color: _type == 'parent'
                        ? primaryBlue
                        : const Color(0xFF7C3AED),
                    size: 32),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(_type == 'parent' ? 'Compte Parent' : 'Compte Élève',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                          _type == 'parent'
                              ? 'Entrez le code parent fourni par l\'école'
                              : 'Entrez le code élève fourni par l\'école',
                          style:
                              const TextStyle(fontSize: 12, color: textGrey)),
                    ])),
              ]),
            ),
            const SizedBox(height: 24),
            const Text('Code d\'accès',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'XXXXXXXX',
                hintStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade300,
                    letterSpacing: 4),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryBlue, width: 2)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, size: 16, color: primaryBlue),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                  'Ce code vous a été fourni par votre établissement scolaire lors de l\'inscription.',
                  style: TextStyle(fontSize: 11, color: primaryBlue),
                )),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _validateCode,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Valider le code',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          // ── Étape 3 — Aperçu + mot de passe ────────────────────────
          if (_step == 3 && _preview != null) ...[
            // Carte aperçu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: successGreen.withValues(alpha: 0.3)),
              ),
              child: Column(children: [
                const Icon(Icons.check_circle_outline,
                    color: successGreen, size: 40),
                const SizedBox(height: 8),
                const Text('Code valide !',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: successGreen)),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                _InfoRow(
                    label: 'Élève',
                    value:
                        '${_preview!['student']?['firstName']} ${_preview!['student']?['lastName']}'),
                const SizedBox(height: 6),
                _InfoRow(
                    label: 'Classe',
                    value: _preview!['student']?['className'] ?? '—'),
                const SizedBox(height: 6),
                _InfoRow(
                    label: 'École',
                    value: _preview!['student']?['schoolName'] ?? '—'),
              ]),
            ),

            const SizedBox(height: 20),

            const Text('Créez votre mot de passe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _PasswordField(
                controller: _passwordCtrl,
                label: 'Mot de passe *',
                show: _showPassword,
                onToggle: () => setState(() => _showPassword = !_showPassword)),
            const SizedBox(height: 12),
            _PasswordField(
                controller: _confirmCtrl,
                label: 'Confirmer le mot de passe *',
                show: _showPassword,
                onToggle: () => setState(() => _showPassword = !_showPassword)),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _createAccount,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Créer mon compte',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          // ── Étape 4 — Succès ─────────────────────────────────────────
          if (_step == 4) ...[
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: successGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline,
                  color: successGreen, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Compte créé avec succès !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Vous êtes maintenant connecté à votre espace ECOLE+',
                style: TextStyle(fontSize: 14, color: textGrey),
                textAlign: TextAlign.center),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Accéder à mon espace',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? color : Colors.grey.shade200,
              width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: selected ? color : const Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: textGrey)),
              ])),
          if (selected) Icon(Icons.check_circle, color: color, size: 22),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: textGrey)),
      Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;

  const _PasswordField(
      {required this.controller,
      required this.label,
      required this.show,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: textGrey)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        obscureText: !show,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Min. 8 caractères',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5)),
          suffixIcon: IconButton(
            icon: Icon(show ? Icons.visibility_off : Icons.visibility,
                size: 18, color: Colors.grey.shade500),
            onPressed: onToggle,
          ),
        ),
      ),
    ]);
  }
}
