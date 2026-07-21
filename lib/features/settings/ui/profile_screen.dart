// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _posteCtrl;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLoadingRemote = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _nameCtrl = TextEditingController(text: p?.fullName ?? '');
    _emailCtrl = TextEditingController(text: p?.email ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _posteCtrl = TextEditingController(text: p?.poste ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromApi());
  }

  Future<void> _loadFromApi() async {
    if (!mounted) return;
    setState(() => _isLoadingRemote = true);
    final ok = await ref.read(profileProvider.notifier).refreshFromApi();
    if (!mounted) return;
    if (ok) {
      final p = ref.read(profileProvider);
      if (p != null && !_isEditing) {
        _nameCtrl.text = p.fullName;
        _emailCtrl.text = p.email;
        _phoneCtrl.text = p.phone;
        _posteCtrl.text = p.poste ?? '';
      }
    }
    setState(() => _isLoadingRemote = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _posteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final error = await ref.read(profileProvider.notifier).syncProfile(
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          poste: _posteCtrl.text.trim(),
        );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      if (error == null) _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null ? 'Profil synchronisé' : error,
        ),
        backgroundColor: error == null ? successGreen : dangerRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child:
                  const Text('Annuler', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ── Avatar ────────────────────────────────────────────
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: primaryBlue.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        profile.initials,
                        style: const TextStyle(
                            color: primaryBlue,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(profile.roleLabel,
                      style: const TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  if (profile.etablissement != null) ...[
                    const SizedBox(height: 2),
                    Text(profile.etablissement!,
                        style: const TextStyle(color: textGrey, fontSize: 12)),
                  ],

                  const SizedBox(height: 28),

                  // ── Champs ─────────────────────────────────────────────
                  _Field(
                    controller: _nameCtrl,
                    label: 'Nom complet',
                    icon: Icons.person_outline,
                    enabled: _isEditing,
                    validator: (v) => v!.trim().isEmpty ? 'Obligatoire' : null,
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    controller: _emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    enabled: false,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'Obligatoire';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    controller: _phoneCtrl,
                    label: 'Téléphone',
                    icon: Icons.phone_outlined,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    controller: _posteCtrl,
                    label: 'Poste / Classe',
                    icon: Icons.work_outline,
                    enabled: _isEditing,
                  ),

                  const SizedBox(height: 28),

                  // ── Bouton sauvegarder ────────────────────────────────
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Sauvegarder',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Infos compte ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Informations du compte',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: textDark)),
                        const SizedBox(height: 12),
                        _InfoRow('Rôle', profile.roleLabel),
                        _InfoRow('ID', profile.id),
                        _InfoRow('Langue', 'Français'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Déconnexion ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: dangerRed),
                      label: const Text('Se déconnecter',
                          style: TextStyle(color: dangerRed)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: dangerRed),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoadingRemote)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}

// ── Champ formulaire ───────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: textGrey),
        filled: true,
        fillColor: enabled ? Colors.white : borderLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderLight)),
        isDense: true,
      ),
    );
  }
}

// ── Ligne info ─────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(color: textGrey, fontSize: 12)),
          ),
          Text(value,
              style: const TextStyle(
                  color: textDark, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
