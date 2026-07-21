import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../student/data/attendance_store.dart';

class JustifyAbsenceScreen extends ConsumerStatefulWidget {
  final AttendanceRecord record;

  const JustifyAbsenceScreen({super.key, required this.record});

  @override
  ConsumerState<JustifyAbsenceScreen> createState() =>
      _JustifyAbsenceScreenState();
}

class _JustifyAbsenceScreenState extends ConsumerState<JustifyAbsenceScreen> {
  final _motifCtrl = TextEditingController();
  bool _isSubmitting = false;

  // Motifs prédéfinis courants en contexte ivoirien
  static const _motifsSuggeres = [
    'Maladie',
    'Décès dans la famille',
    'Cérémonie familiale',
    'Problème de transport',
    'Rendez-vous médical',
    'Autre',
  ];

  @override
  void dispose() {
    _motifCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_motifCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez indiquer un motif')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(attendanceProvider.notifier).justifyAbsence(
            recordId: widget.record.id,
            motif: _motifCtrl.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Justification envoyée — en attente de validation'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Échec de l\'envoi de la justification'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Justifier une absence'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Résumé de l'absence ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dangerRed.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dangerRed.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.record.studentName,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                      icon: Icons.book_outlined, text: widget.record.subject),
                  _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text:
                          '${widget.record.date} • ${widget.record.duration}'),
                  _InfoRow(
                      icon: Icons.class_outlined,
                      text: widget.record.className),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Motifs suggérés ─────────────────────────────────────
            const Text(
              'Motif de l\'absence',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _motifsSuggeres.map((motif) {
                final selected = _motifCtrl.text == motif;
                return ChoiceChip(
                  label: Text(motif),
                  selected: selected,
                  selectedColor: primaryBlue.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: selected ? primaryBlue : textDark,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _motifCtrl.text = motif),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ── Champ texte libre ───────────────────────────────────
            TextField(
              controller: _motifCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Précisez le motif...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 32),

            // ── Bouton envoyer ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Envoyer la justification',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textGrey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: textGrey, fontSize: 13)),
        ],
      ),
    );
  }
}
