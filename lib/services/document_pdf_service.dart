import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Génération PDF simple pour attestations et certificats (hors bulletin).
class DocumentPdfService {
  static Future<Uint8List> generateAttestation({
    required String schoolName,
    required String studentName,
    required String className,
    String? registrationNo,
    String? schoolCity,
  }) async {
    final pdf = pw.Document();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                schoolName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if (schoolCity != null && schoolCity.isNotEmpty)
              pw.Center(
                child: pw.Text(schoolCity,
                    style: const pw.TextStyle(fontSize: 10)),
              ),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text(
                'ATTESTATION DE SCOLARITÉ',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
            pw.SizedBox(height: 32),
            pw.Text(
              'Je soussigné(e), Chef d\'établissement de $schoolName, '
              'certifie que l\'élève :',
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              studentName.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (registrationNo != null && registrationNo.isNotEmpty)
              pw.Text('Matricule : $registrationNo',
                  style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 8),
            pw.Text(
              'Est régulièrement inscrit(e) en classe de $className '
              'pour l\'année scolaire en cours.',
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
            ),
            pw.SizedBox(height: 48),
            pw.Text(
              'En foi de quoi, la présente attestation est délivrée '
              'pour servir et valoir ce que de droit.',
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Fait à ${schoolCity ?? '—'}, le $today',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 32),
                  pw.Text('Le Chef d\'établissement',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('(Signature et cachet)',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                'Document généré par ECOLE+',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static Future<Uint8List> generateCertificat({
    required String schoolName,
    required String studentName,
    required String className,
    String? registrationNo,
    String? schoolCity,
  }) async {
    final pdf = pw.Document();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'RÉPUBLIQUE DE CÔTE D\'IVOIRE',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Ministère de l\'Éducation Nationale',
                style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 20),
            pw.Text(
              schoolName.toUpperCase(),
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 28),
            pw.Text(
              'CERTIFICAT DE SCOLARITÉ',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 32),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Nom et prénoms : $studentName',
                      style: const pw.TextStyle(fontSize: 12)),
                  if (registrationNo != null)
                    pw.Text('Matricule : $registrationNo',
                        style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('Classe : $className',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Certifie que l\'intéressé(e) fréquente assidûment '
                    'les cours dans notre établissement.',
                    style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Fait à ${schoolCity ?? '—'}, le $today',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Text(
              'Document généré par ECOLE+',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static Future<Uint8List> generateReleveNotes({
    required String schoolName,
    required String studentName,
    required String className,
    required String trimestre,
    required List<Map<String, dynamic>> grades,
    double? moyenne,
  }) async {
    final pdf = pw.Document();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              schoolName.toUpperCase(),
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'RELEVÉ DE NOTES — $trimestre',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Élève : $studentName',
                style: const pw.TextStyle(fontSize: 11)),
            pw.Text('Classe : $className',
                style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Matière', 'Type', 'Note', 'Coef.'],
              data: grades
                  .map((g) => [
                        g['subject']?.toString() ?? '',
                        g['evalType']?.toString() ?? '',
                        '${(g['value'] as num?)?.toStringAsFixed(1) ?? '—'}/20',
                        '${g['coefficient'] ?? 1}',
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 22,
            ),
            if (moyenne != null) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'Moyenne générale : ${moyenne.toStringAsFixed(2)}/20',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Édité le $today',
                  style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Document généré par ECOLE+',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }
}
