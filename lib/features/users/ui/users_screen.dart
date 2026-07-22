import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';

const _roleLabels = {
  'ADMIN': 'Administrateur',
  'FOUNDER': 'Fondateur',
  'DIRECTOR': 'Directeur',
  'CENSOR': 'Censeur',
  'SURVEILLANT': 'Surveillant Général',
  'SECRETARY': 'Secrétaire',
  'ACCOUNTANT': 'Comptable',
  'CASHIER': 'Caissier',
  'TEACHER': 'Enseignant',
  'EDUCATOR': 'Éducateur',
  'PARENT': 'Parent',
  'STUDENT': 'Élève',
};

const _roleColors = {
  'ADMIN': Color(0xFFDC2626),
  'FOUNDER': Color(0xFF7C3AED),
  'DIRECTOR': Color(0xFF1D4ED8),
  'CENSOR': Color(0xFF4338CA),
  'SURVEILLANT': Color(0xFFEA580C),
  'SECRETARY': Color(0xFF0D9488),
  'ACCOUNTANT': Color(0xFF16A34A),
  'CASHIER': Color(0xFF059669),
  'TEACHER': Color(0xFFCA8A04),
  'EDUCATOR': Color(0xFFDB2777),
  'PARENT': Color(0xFF6B7280),
  'STUDENT': Color(0xFF0284C7),
};

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient.instance.get('/users');
      if (!mounted) {
        return;
      }
      setState(() {
        _users = response.data as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      debugPrint('ECOLE+ users: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> user) async {
    final isActive = user['isActive'] as bool? ?? true;
    try {
      final action = isActive ? 'deactivate' : 'activate';
      await ApiClient.instance.patch('/users/${user['id']}/$action');
      if (!mounted) {
        return;
      }
      setState(() {
        _users = _users.map((u) {
          if (u['id'] == user['id']) {
            return {...u, 'isActive': !isActive};
          }
          return u;
        }).toList();
      });
    } catch (e) {
      debugPrint('ECOLE+ toggle: $e');
    }
  }

  Future<void> _resetPassword(String userId) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Réinitialiser le mot de passe',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Saisissez le nouveau mot de passe :',
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Min. 8 caractères',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    if (ctrl.text.length < 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 8 caractères'),
          backgroundColor: dangerRed,
        ));
      }
      return;
    }

    try {
      await ApiClient.instance.patch('/users/$userId/reset-password',
          data: {'newPassword': ctrl.text});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Mot de passe réinitialisé'),
          backgroundColor: successGreen,
        ));
      }
    } catch (e) {
      debugPrint('ECOLE+ reset: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = ref.watch(authProvider).isOwner;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Utilisateurs',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text('${_users.length} compte(s)',
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateUserScreen()),
                );
                if (created == true) {
                  _loadUsers();
                }
              },
              backgroundColor: primaryBlue,
              child:
                  const Icon(Icons.person_add_outlined, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.people_outline,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Aucun utilisateur',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _users.length,
                    itemBuilder: (ctx, i) {
                      final user = _users[i] as Map<String, dynamic>;
                      final isActive = user['isActive'] as bool? ?? true;
                      final role = user['role'] as String? ?? '';
                      final roleLabel = _roleLabels[role] ?? role;
                      final roleColor = _roleColors[role] ?? textGrey;
                      final firstName = user['firstName'] as String? ?? '';
                      final lastName = user['lastName'] as String? ?? '';
                      final initials =
                          '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                (isActive ? roleColor : Colors.grey)
                                    .withValues(alpha: 0.15),
                            child: Text(initials,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? roleColor : Colors.grey)),
                          ),
                          title: Row(children: [
                            Text('$firstName $lastName',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isActive
                                        ? const Color(0xFF1F2937)
                                        : Colors.grey)),
                            const SizedBox(width: 6),
                            if (!isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Inactif',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              ),
                          ]),
                          subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(user['email'] as String? ?? '',
                                    style: const TextStyle(
                                        fontSize: 12, color: textGrey)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(roleLabel,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: roleColor)),
                                ),
                              ]),
                          trailing: canWrite
                              ? PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      color: textGrey),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  onSelected: (val) {
                                    if (val == 'toggle') {
                                      _toggleStatus(user);
                                    }
                                    if (val == 'reset') {
                                      _resetPassword(user['id'] as String);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'reset',
                                      child: Row(children: [
                                        Icon(Icons.key_outlined,
                                            size: 18, color: primaryBlue),
                                        SizedBox(width: 8),
                                        Text('Réinitialiser mot de passe'),
                                      ]),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(children: [
                                        Icon(
                                          isActive
                                              ? Icons.block_outlined
                                              : Icons.check_circle_outline,
                                          size: 18,
                                          color: isActive
                                              ? dangerRed
                                              : successGreen,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(isActive
                                            ? 'Désactiver le compte'
                                            : 'Activer le compte'),
                                      ]),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

// ── Écran création utilisateur ─────────────────────────────────────────────
class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'TEACHER';
  bool _saving = false;
  String? _error;
  bool _showPassword = false;

  static const _roles = [
    ('DIRECTOR', 'Directeur / Proviseur'),
    ('CENSOR', 'Censeur / Dir. études'),
    ('SURVEILLANT', 'Surveillant Général'),
    ('SECRETARY', 'Secrétaire Scolarité'),
    ('ACCOUNTANT', 'Comptable'),
    ('CASHIER', 'Caissier'),
    ('TEACHER', 'Enseignant'),
    ('EDUCATOR', 'Éducateur'),
  ];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.length < 8) {
      setState(() => _error =
          'Tous les champs sont obligatoires (mot de passe min. 8 caractères)');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient.instance.post('/users', data: {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'role': _role,
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().contains('existe')
            ? 'Cet email est déjà utilisé'
            : 'Erreur lors de la création';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Créer un compte',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Informations personnelles',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _Field(
                        controller: _firstNameCtrl,
                        label: 'Prénom *',
                        hint: 'Jean')),
                const SizedBox(width: 10),
                Expanded(
                    child: _Field(
                        controller: _lastNameCtrl,
                        label: 'Nom *',
                        hint: 'Kouassi')),
              ]),
              const SizedBox(height: 10),
              _Field(
                  controller: _emailCtrl,
                  label: 'Email *',
                  hint: 'prenom.nom@ecole.ci',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              const Text('Mot de passe provisoire *',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textGrey)),
              const SizedBox(height: 4),
              TextField(
                controller: _passwordCtrl,
                obscureText: !_showPassword,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Min. 8 caractères',
                  hintStyle:
                      TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: primaryBlue, width: 1.5)),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: Colors.grey.shade500),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Rôle dans l\'établissement',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              for (final r in _roles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _role = r.$1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _role == r.$1
                            ? primaryBlue.withValues(alpha: 0.05)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _role == r.$1
                              ? primaryBlue
                              : Colors.grey.shade200,
                          width: _role == r.$1 ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Expanded(
                            child: Text(r.$2,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _role == r.$1
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: _role == r.$1
                                        ? primaryBlue
                                        : const Color(0xFF1F2937)))),
                        if (_role == r.$1)
                          const Icon(Icons.check_circle,
                              color: primaryBlue, size: 18),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Créer le compte',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
                'La personne pourra modifier son mot de passe depuis son profil',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final TextInputType? keyboardType;

  const _Field(
      {required this.controller,
      required this.label,
      required this.hint,
      this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: textGrey)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5)),
        ),
      ),
    ]);
  }
}
