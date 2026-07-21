import 'package:flutter/material.dart';
import '../../../core/services/enrollments_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dio_error_message.dart';
import 'package:dio/dio.dart';

/// Formulaire de pré-inscription (public, sans connexion).
class EnrollmentFormScreen extends StatefulWidget {
  final String? initialTenantCode;

  const EnrollmentFormScreen({super.key, this.initialTenantCode});

  @override
  State<EnrollmentFormScreen> createState() => _EnrollmentFormScreenState();
}

class _EnrollmentFormScreenState extends State<EnrollmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenantCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _parentNameCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  final _parentEmailCtrl = TextEditingController();
  final _levelCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _gender = 'MALE';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTenantCode != null) {
      _tenantCtrl.text = widget.initialTenantCode!;
    }
  }

  @override
  void dispose() {
    _tenantCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _parentNameCtrl.dispose();
    _parentPhoneCtrl.dispose();
    _parentEmailCtrl.dispose();
    _levelCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await EnrollmentsApiService.submitPublic({
        'tenantCode': _tenantCtrl.text.trim().toUpperCase(),
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'gender': _gender,
        'levelRequested': _levelCtrl.text.trim().isEmpty
            ? null
            : _levelCtrl.text.trim(),
        'parentName': _parentNameCtrl.text.trim(),
        'parentPhone': _parentPhoneCtrl.text.trim(),
        if (_parentEmailCtrl.text.trim().isNotEmpty)
          'parentEmail': _parentEmailCtrl.text.trim(),
        if (_addressCtrl.text.trim().isNotEmpty)
          'address': _addressCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Demande envoyée'),
          content: const Text(
            'Votre demande de pré-inscription a été enregistrée. '
            'Le secrétariat vous contactera.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Pré-inscription'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Demande d\'inscription',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 4),
              const Text(
                'Remplissez le formulaire. L\'école traitera votre demande.',
                style: TextStyle(color: textGrey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _tenantCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code établissement *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Prénom élève *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom élève *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('Garçon')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('Fille')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'MALE'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _levelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Niveau souhaité (ex. 6ème, Terminale A)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Responsable légal',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _parentNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du parent *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _parentPhoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _parentEmailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email (optionnel)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Remarques (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Envoyer la demande',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
