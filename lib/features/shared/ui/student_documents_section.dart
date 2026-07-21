import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/document_pdf_service.dart';

/// Boutons de génération PDF (attestation, certificat, relevé).
class StudentDocumentsSection extends ConsumerStatefulWidget {
  final String studentName;
  final String className;
  final String? registrationNo;
  final List<Map<String, dynamic>> grades;
  final double? moyenne;
  final String trimestre;

  const StudentDocumentsSection({
    super.key,
    required this.studentName,
    required this.className,
    this.registrationNo,
    this.grades = const [],
    this.moyenne,
    this.trimestre = '1er',
  });

  @override
  ConsumerState<StudentDocumentsSection> createState() =>
      _StudentDocumentsSectionState();
}

class _StudentDocumentsSectionState
    extends ConsumerState<StudentDocumentsSection> {
  bool _generating = false;

  Future<void> _generate(Future<Uint8List> Function() builder, String name) async {
    setState(() => _generating = true);
    try {
      final bytes = await builder();
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: name,
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final schoolName = auth.tenantName ?? 'Établissement';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Documents',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
        const SizedBox(height: 8),
        if (_generating)
          const LinearProgressIndicator(color: primaryBlue),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DocButton(
              icon: Icons.verified_outlined,
              label: 'Attestation',
              enabled: !_generating,
              onTap: () => _generate(
                () => DocumentPdfService.generateAttestation(
                  schoolName: schoolName,
                  studentName: widget.studentName,
                  className: widget.className,
                  registrationNo: widget.registrationNo,
                ),
                'Attestation_${widget.studentName}',
              ),
            ),
            _DocButton(
              icon: Icons.card_membership_outlined,
              label: 'Certificat',
              enabled: !_generating,
              onTap: () => _generate(
                () => DocumentPdfService.generateCertificat(
                  schoolName: schoolName,
                  studentName: widget.studentName,
                  className: widget.className,
                  registrationNo: widget.registrationNo,
                ),
                'Certificat_${widget.studentName}',
              ),
            ),
            if (widget.grades.isNotEmpty)
              _DocButton(
                icon: Icons.list_alt_outlined,
                label: 'Relevé de notes',
                enabled: !_generating,
                onTap: () => _generate(
                  () => DocumentPdfService.generateReleveNotes(
                    schoolName: schoolName,
                    studentName: widget.studentName,
                    className: widget.className,
                    trimestre: widget.trimestre,
                    grades: widget.grades,
                    moyenne: widget.moyenne,
                  ),
                  'Releve_${widget.studentName}_${widget.trimestre}',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DocButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _DocButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: BorderSide(color: primaryBlue.withValues(alpha: 0.4)),
      ),
    );
  }
}
