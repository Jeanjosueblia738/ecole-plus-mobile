import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../features/grades/data/grade_model.dart';

class BulletinPdfService {
  static Future<Uint8List> generate(Bulletin bulletin) async {
    final pdf = pw.Document();
    final dateGen = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── En-tête établissement ─────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ECOLE+',
                        style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800)),
                    pw.Text('Plateforme Éducative Intelligente',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('BULLETIN DE NOTES',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${bulletin.trimestre} Trimestre',
                        style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('Généré le $dateGen',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey500)),
                  ],
                ),
              ],
            ),

            pw.Divider(color: PdfColors.blue800, thickness: 1.5),
            pw.SizedBox(height: 8),

            // ── Infos élève ───────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Élève : ${bulletin.studentName}',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.Text('Classe : ${bulletin.className}',
                            style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                          'Rang : ${bulletin.rang} / ${bulletin.totalEleves}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Text(
                          'Moyenne générale : ${bulletin.moyenneGenerale.toStringAsFixed(2)} / 20',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: bulletin.estAdmis
                                  ? PdfColors.green800
                                  : PdfColors.red800)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Tableau des notes ─────────────────────────────────
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FixedColumnWidth(40),
                2: const pw.FixedColumnWidth(55),
                3: const pw.FixedColumnWidth(70),
              },
              children: [
                // En-tête
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _cell('Matière', isHeader: true),
                    _cell('Coef.', isHeader: true),
                    _cell('Moyenne', isHeader: true),
                    _cell('Points', isHeader: true),
                  ],
                ),
                // Lignes matières
                ...bulletin.results.map((r) => pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color:
                            r.moyenne < 10 ? PdfColors.red50 : PdfColors.white,
                      ),
                      children: [
                        _cell(r.subject),
                        _cell('${r.coefficient}'),
                        _cell(r.moyenne.toStringAsFixed(2),
                            bold: true,
                            color: r.moyenne < 10
                                ? PdfColors.red700
                                : PdfColors.black),
                        _cell(r.moyennePonderee.toStringAsFixed(2)),
                      ],
                    )),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Résumé final ──────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: bulletin.estAdmis ? PdfColors.green50 : PdfColors.red50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(
                  color:
                      bulletin.estAdmis ? PdfColors.green300 : PdfColors.red300,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                          'Moyenne générale : ${bulletin.moyenneGenerale.toStringAsFixed(2)} / 20',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 13)),
                      pw.Text('Mention : ${bulletin.mention}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: bulletin.estAdmis
                                  ? PdfColors.green800
                                  : PdfColors.red800)),
                    ],
                  ),
                  pw.Text(
                    bulletin.estAdmis ? 'ADMIS(E)' : 'NON ADMIS(E)',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                        color: bulletin.estAdmis
                            ? PdfColors.green800
                            : PdfColors.red800),
                  ),
                ],
              ),
            ),

            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.Text(
              'Document généré automatiquement par ECOLE+ — Ne pas reproduire sans autorisation',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _cell(String text,
      {bool isHeader = false,
      bool bold = false,
      PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 10,
          fontWeight:
              isHeader || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : color,
        ),
      ),
    );
  }
}
