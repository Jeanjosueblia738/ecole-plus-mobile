import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/services/tenants_api_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/theme/app_colors.dart';

/// Sélecteur d'établissement pour les groupes scolaires (staff).
/// Note : le JWT reste lié à l'établissement de connexion — un nouveau login
/// avec le code de l'autre établissement est nécessaire pour changer réellement.
class TenantGroupSelector extends ConsumerStatefulWidget {
  const TenantGroupSelector({super.key});

  @override
  ConsumerState<TenantGroupSelector> createState() =>
      _TenantGroupSelectorState();
}

class _TenantGroupSelectorState extends ConsumerState<TenantGroupSelector> {
  Map<String, dynamic>? _groupData;
  bool _loading = true;
  String? _preferredCode;

  static const _staffRoles = {
    UserRole.admin,
    UserRole.founder,
    UserRole.director,
    UserRole.censor,
    UserRole.secretary,
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final role = ref.read(authProvider).role;
    if (role == null || !_staffRoles.contains(role)) {
      setState(() => _loading = false);
      return;
    }
    _preferredCode = await AuthStorageService.read('preferred_tenant_code');
    try {
      final data = await TenantsApiService.getMyGroup();
      if (mounted) {
        setState(() {
          _groupData = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectTenant(String code, String name) async {
    await AuthStorageService.write('preferred_tenant_code', code);
    await AuthStorageService.write('preferred_tenant_name', name);
    setState(() => _preferredCode = code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Préférence enregistrée ($name). '
          'Reconnectez-vous avec le code $code pour accéder à cet établissement.',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final tenants = (_groupData?['tenants'] as List<dynamic>?) ?? [];
    if (tenants.length <= 1) return const SizedBox.shrink();

    final auth = ref.watch(authProvider);
    final currentCode = auth.tenantCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.apartment_outlined, color: primaryBlue, size: 20),
              SizedBox(width: 8),
              Text('Groupe scolaire',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          if (_groupData?['group']?['name'] != null) ...[
            const SizedBox(height: 4),
            Text(
              _groupData!['group']['name'].toString(),
              style: const TextStyle(fontSize: 12, color: textGrey),
            ),
          ],
          const SizedBox(height: 10),
          ...tenants.map((t) {
            final code = t['code']?.toString() ?? '';
            final name = t['name']?.toString() ?? code;
            final isCurrent = code == currentCode;
            final isPreferred = code == _preferredCode;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isCurrent ? Icons.check_circle : Icons.circle_outlined,
                color: isCurrent ? successGreen : textGrey,
                size: 20,
              ),
              title: Text(name, style: const TextStyle(fontSize: 13)),
              subtitle: Text(code, style: const TextStyle(fontSize: 11)),
              trailing: isPreferred && !isCurrent
                  ? const Text('Préféré',
                      style: TextStyle(fontSize: 10, color: primaryBlue))
                  : null,
              onTap: isCurrent
                  ? null
                  : () => _selectTenant(code, name),
            );
          }),
          const SizedBox(height: 4),
          const Text(
            'Le changement d\'établissement nécessite une reconnexion avec le code correspondant.',
            style: TextStyle(fontSize: 10, color: textGrey),
          ),
        ],
      ),
    );
  }
}
