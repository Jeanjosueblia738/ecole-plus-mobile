// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/tenant_brand.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/tenants_api_service.dart';
import '../../../core/theme/app_colors.dart';

/// Paramètres identité documents (OWNER : Admin / Fondateur).
class BrandingSettingsScreen extends ConsumerStatefulWidget {
  const BrandingSettingsScreen({super.key});

  @override
  ConsumerState<BrandingSettingsScreen> createState() =>
      _BrandingSettingsScreenState();
}

class _BrandingSettingsScreenState
    extends ConsumerState<BrandingSettingsScreen> {
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _logoUrl = TextEditingController();
  final _header = TextEditingController();
  final _footer = TextEditingController();
  final _motto = TextEditingController();
  final _director = TextEditingController();
  final _drena = TextEditingController();
  String _status = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _logoUrl.dispose();
    _header.dispose();
    _footer.dispose();
    _motto.dispose();
    _director.dispose();
    _drena.dispose();
    super.dispose();
  }

  void _fill(TenantBrand b) {
    _phone.text = b.phone ?? '';
    _address.text = b.address ?? '';
    _logoUrl.text = b.logoUrl ?? '';
    _header.text = b.docHeaderLine ?? '';
    _footer.text = b.docFooterLine ?? '';
    _motto.text = b.motto ?? '';
    _director.text = b.directorName ?? '';
    _drena.text = b.drena ?? '';
    _status = b.schoolStatus ?? '';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final brand = await TenantsApiService.getMe();
      if (!mounted) return;
      _fill(brand);
      await ref.read(authProvider.notifier).updateBrand(brand);
    } catch (_) {
      final local = ref.read(authProvider).schoolBrand;
      _fill(local);
      _error =
          'Impossible de charger depuis le serveur — valeurs locales affichées.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final brand = await TenantsApiService.updateBranding({
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'logoUrl': _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
        'docHeaderLine':
            _header.text.trim().isEmpty ? null : _header.text.trim(),
        'docFooterLine':
            _footer.text.trim().isEmpty ? null : _footer.text.trim(),
        'motto': _motto.text.trim().isEmpty ? null : _motto.text.trim(),
        'directorName':
            _director.text.trim().isEmpty ? null : _director.text.trim(),
        'schoolStatus': _status.isEmpty ? null : _status,
        'drena': _drena.text.trim().isEmpty ? null : _drena.text.trim(),
      });
      if (!mounted) return;
      await ref.read(authProvider.notifier).updateBrand(brand);
      if (!mounted) return;
      _fill(brand);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identité documents enregistrée')),
      );
    } catch (e) {
      setState(() {
        _error =
            'Enregistrement impossible. Vérifiez l’URL logo (https) et réessayez.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Identité & documents'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  auth.tenantName ?? 'Établissement',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Logo, en-tête et pied de page pour bulletins, attestations et reçus. '
                  'Pour l’upload du logo, utilisez le web (Paramètres) puis collez l’URL ici si besoin.',
                  style: TextStyle(fontSize: 12, color: textGrey),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(color: Colors.orange, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                _field('URL logo (https)', _logoUrl),
                if (_logoUrl.text.trim().startsWith('https://'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _logoUrl.text.trim(),
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                _field('Adresse', _address),
                _field('Téléphone', _phone,
                    keyboard: TextInputType.phone),
                _field('Ligne d\'en-tête', _header),
                _field('Pied de page', _footer),
                _field('Devise', _motto),
                _field('Directeur', _director),
                _field('DRENA / Inspection', _drena),
                const Text('Statut',
                    style: TextStyle(fontSize: 12, color: textGrey)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _status.isEmpty ? null : _status,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Public', child: Text('Public')),
                    DropdownMenuItem(value: 'Privé', child: Text('Privé')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? ''),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryBlue,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
