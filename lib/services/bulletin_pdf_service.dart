import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../features/grades/data/grade_model.dart';

/// Options établissement / classe pour le format MEN.
class BulletinPdfOptions {
  final String schoolName;
  final String schoolCode;
  final String schoolCity;
  final String? drena;
  final String year;
  final String? registrationNo;
  final double? classAverage;
  final double? classMin;
  final double? classMax;
  final String? motto;

  const BulletinPdfOptions({
    this.schoolName = 'ÉTABLISSEMENT',
    this.schoolCode = '',
    this.schoolCity = '',
    this.drena,
    this.year = '2025-2026',
    this.registrationNo,
    this.classAverage,
    this.classMin,
    this.classMax,
    this.motto,
  });
}

class BulletinPdfService {
  static const _letters = [
    'français',
    'francais',
    'anglais',
    'allemand',
    'espagnol',
    'histoire',
    'géographie',
    'geographie',
    'philosophie',
    'littérature',
    'litterature',
  ];
  static const _sciences = [
    'mathématiques',
    'mathematiques',
    'maths',
    'physique',
    'chimie',
    'physique-chimie',
    'svt',
    'sciences',
  ];

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .trim();

  static String _group(String subject) {
    final n = _norm(subject);
    if (_letters.any((k) => n.contains(_norm(k)))) return 'LETTRES';
    if (_sciences.any((k) => n.contains(_norm(k)))) return 'SCIENCES';
    return 'AUTRES';
  }

  static String _trimestreLabel(String t) {
    final u = t.toUpperCase();
    if (u.contains('2') || u.contains('T2')) return '2ème Trimestre';
    if (u.contains('3') || u.contains('T3')) return '3ème Trimestre';
    return '1er Trimestre';
  }

  static String _appreciation(double note) {
    if (note >= 16) return 'Très bien';
    if (note >= 14) return 'Bien';
    if (note >= 12) return 'Assez bien';
    if (note >= 10) return 'Passable';
    if (note >= 8) return 'Insuffisant';
    return 'Médiocre';
  }

  static String _mentionConseil(double moy) {
    if (moy >= 16) return 'Félicitations';
    if (moy >= 14) return 'Tableau d\'Honneur';
    if (moy >= 12) return 'Encouragements';
    if (moy >= 10) return 'À encourager';
    return 'Avertissement travail';
  }

  static Future<Uint8List> generate(
    Bulletin bulletin, {
    BulletinPdfOptions options = const BulletinPdfOptions(),
  }) async {
    final pdf = pw.Document();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final moy = bulletin.moyenneGenerale;
    final ment = _mentionConseil(moy);

    final lettres =
        bulletin.results.where((r) => _group(r.subject) == 'LETTRES').toList();
    final sciences =
        bulletin.results.where((r) => _group(r.subject) == 'SCIENCES').toList();
    final autres =
        bulletin.results.where((r) => _group(r.subject) == 'AUTRES').toList();

    double bilanMoy(List<SubjectResult> list) {
      final coef = list.fold<int>(0, (s, r) => s + r.coefficient);
      if (coef == 0) return 0;
      return list.fold<double>(0, (s, r) => s + r.moyennePonderee) / coef;
    }

    int bilanCoef(List<SubjectResult> list) =>
        list.fold(0, (s, r) => s + r.coefficient);

    double bilanPoints(List<SubjectResult> list) =>
        list.fold(0.0, (s, r) => s + r.moyennePonderee);

    final totCoef = bulletin.results.fold<int>(0, (s, r) => s + r.coefficient);
    final totPoints =
        bulletin.results.fold<double>(0, (s, r) => s + r.moyennePonderee);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 28),
        build: (context) => [
          // ── En-tête MEN ─────────────────────────────────────
          pw.Center(
            child: pw.Column(children: [
              pw.Text(
                'MINISTÈRE DE L\'ÉDUCATION NATIONALE ET DE L\'ALPHABÉTISATION',
                style: pw.TextStyle(
                    fontSize: 8, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                options.drena ??
                    'DRENA DE ${options.schoolCity.toUpperCase().isEmpty ? '—' : options.schoolCity.toUpperCase()}',
                style: const pw.TextStyle(fontSize: 7.5),
                textAlign: pw.TextAlign.center,
              ),
            ]),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      options.schoolName.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    if (options.schoolCity.isNotEmpty)
                      pw.Text(options.schoolCity,
                          style: const pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Code : ${options.schoolCode.isEmpty ? '—' : options.schoolCode}',
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    width: 36,
                    height: 36,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.6),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text('QR\nCODE',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 6)),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 0.8, color: PdfColors.black),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'BULLETIN TRIMESTRIEL DE NOTES — ${_trimestreLabel(bulletin.trimestre)}',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Center(
            child: pw.Text('Année scolaire ${options.year}',
                style: const pw.TextStyle(fontSize: 9)),
          ),
          pw.SizedBox(height: 8),

          // ── Identité ────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        bulletin.studentName.toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Matricule : ${options.registrationNo ?? bulletin.studentId}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text('Classe : ${bulletin.className}',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Effectif : ${bulletin.totalEleves}',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                pw.Container(
                  width: 52,
                  height: 58,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.5),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text('Photo',
                      style: const pw.TextStyle(
                          fontSize: 7, color: PdfColors.grey600)),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // ── Tableau ─────────────────────────────────────────
          _buildTable(
            lettres: lettres,
            sciences: sciences,
            autres: autres,
            bilanMoy: bilanMoy,
            bilanCoef: bilanCoef,
            bilanPoints: bilanPoints,
            totCoef: totCoef,
            totPoints: totPoints,
            moyenneGenerale: moy,
          ),
          pw.SizedBox(height: 10),

          // ── Résumé 3 blocs ──────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _summaryBox(
                  'ASSIDUITÉ',
                  [
                    'Absences : 0 h',
                    'Justifiées : 0 h',
                    'Non justifiées : 0 h',
                  ],
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: _summaryBox(
                  'MOYENNE TRIMESTRIELLE',
                  [
                    '${moy.toStringAsFixed(2)} / 20',
                    'Rang : ${bulletin.rang}e / ${bulletin.totalEleves}',
                  ],
                  centerLarge: true,
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: _summaryBox(
                  'RÉSULTATS DE CLASSE',
                  [
                    'Moy. classe : ${options.classAverage != null ? options.classAverage!.toStringAsFixed(2) : '—'}',
                    'Moy. min : ${options.classMin != null ? options.classMin!.toStringAsFixed(2) : '—'}',
                    'Moy. max : ${options.classMax != null ? options.classMax!.toStringAsFixed(2) : '—'}',
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // ── Mentions / Appréciations / Chef ─────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  height: 110,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Center(
                        child: pw.Text('MENTIONS DU CONSEIL',
                            style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(height: 6),
                      ...[
                        'Tableau d\'Honneur',
                        'Encouragements',
                        'Félicitations',
                        'Avertissement travail',
                        'Blâme',
                      ].map((c) {
                        final marked = c == ment ||
                            (ment == 'À encourager' && c == 'Encouragements');
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: pw.Row(children: [
                            pw.Container(
                              width: 8,
                              height: 8,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(width: 0.5),
                              ),
                              alignment: pw.Alignment.center,
                              child: marked
                                  ? pw.Text('X',
                                      style: pw.TextStyle(
                                          fontSize: 6,
                                          fontWeight: pw.FontWeight.bold))
                                  : pw.SizedBox(),
                            ),
                            pw.SizedBox(width: 4),
                            pw.Text(c,
                                style: const pw.TextStyle(fontSize: 7)),
                          ]),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Container(
                  height: 110,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.6),
                  ),
                  child: pw.Column(children: [
                    pw.Text('APPRÉCIATIONS DU CONSEIL',
                        style: pw.TextStyle(
                            fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 16),
                    pw.Text(_appreciation(moy),
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontStyle: pw.FontStyle.italic,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Spacer(),
                    pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text('Le professeur principal',
                          style: const pw.TextStyle(fontSize: 7)),
                    ),
                    pw.Divider(thickness: 0.4),
                  ]),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Container(
                  height: 110,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.6),
                  ),
                  child: pw.Column(children: [
                    pw.Text('LE CHEF D\'ÉTABLISSEMENT',
                        style: pw.TextStyle(
                            fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Fait à ${options.schoolCity.isEmpty ? '—' : options.schoolCity}, le $today',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                    pw.Spacer(),
                    pw.Text('Signature et cachet',
                        style: const pw.TextStyle(fontSize: 7)),
                  ]),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
              options.motto ??
                  'L\'excellence, notre ambition — Document généré par ECOLE+',
              style: const pw.TextStyle(
                  fontSize: 7, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _summaryBox(
    String title,
    List<String> lines, {
    bool centerLarge = false,
  }) {
    return pw.Container(
      height: 64,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: centerLarge
            ? pw.CrossAxisAlignment.center
            : pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 7, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 6),
          if (centerLarge && lines.isNotEmpty) ...[
            pw.Text(lines.first,
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold)),
            if (lines.length > 1)
              pw.Text(lines[1], style: const pw.TextStyle(fontSize: 7.5)),
          ] else
            ...lines.map((l) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(l, style: const pw.TextStyle(fontSize: 7)),
                )),
        ],
      ),
    );
  }

  static pw.Widget _buildTable({
    required List<SubjectResult> lettres,
    required List<SubjectResult> sciences,
    required List<SubjectResult> autres,
    required double Function(List<SubjectResult>) bilanMoy,
    required int Function(List<SubjectResult>) bilanCoef,
    required double Function(List<SubjectResult>) bilanPoints,
    required int totCoef,
    required double totPoints,
    required double moyenneGenerale,
  }) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey800),
        children: [
          _h('Disciplines'),
          _h('Moy.'),
          _h('Coef.'),
          _h('Total'),
          _h('Rang'),
          _h('Appréciations'),
          _h('Prof.'),
          _h('Sign.'),
        ],
      ),
    ];

    void addHeader(String title) {
      rows.add(pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
          ),
          ...List.generate(7, (_) => pw.SizedBox()),
        ],
      ));
    }

    void addLine(SubjectResult r) {
      rows.add(pw.TableRow(children: [
        _c(r.subject, align: pw.TextAlign.left),
        _c(r.moyenne.toStringAsFixed(2)),
        _c('${r.coefficient}'),
        _c(r.moyennePonderee.toStringAsFixed(2)),
        _c('—'),
        _c(_appreciation(r.moyenne), align: pw.TextAlign.left),
        _c(''),
        _c(''),
      ]));
    }

    void addBilan(String label, List<SubjectResult> list) {
      if (list.isEmpty) return;
      rows.add(pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _c(label, bold: true, align: pw.TextAlign.left),
          _c(bilanMoy(list).toStringAsFixed(2), bold: true),
          _c('${bilanCoef(list)}', bold: true),
          _c(bilanPoints(list).toStringAsFixed(2), bold: true),
          _c(''),
          _c(''),
          _c(''),
          _c(''),
        ],
      ));
    }

    if (lettres.isNotEmpty) {
      addHeader('BILAN LETTRES');
      for (final r in lettres) {
        addLine(r);
      }
      addBilan('Sous-total Lettres', lettres);
    }
    if (sciences.isNotEmpty) {
      addHeader('BILAN SCIENCES');
      for (final r in sciences) {
        addLine(r);
      }
      addBilan('Sous-total Sciences', sciences);
    }
    if (autres.isNotEmpty) {
      addHeader('AUTRES DISCIPLINES');
      for (final r in autres) {
        addLine(r);
      }
    }

    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey400),
      children: [
        _c('TOTAUX', bold: true, align: pw.TextAlign.left),
        _c(moyenneGenerale.toStringAsFixed(2), bold: true),
        _c('$totCoef', bold: true),
        _c(totPoints.toStringAsFixed(2), bold: true),
        _c(''),
        _c(''),
        _c(''),
        _c(''),
      ],
    ));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(3.2),
        1: const pw.FixedColumnWidth(32),
        2: const pw.FixedColumnWidth(28),
        3: const pw.FixedColumnWidth(38),
        4: const pw.FixedColumnWidth(28),
        5: const pw.FlexColumnWidth(2),
        6: const pw.FixedColumnWidth(36),
        7: const pw.FixedColumnWidth(28),
      },
      children: rows,
    );
  }

  static pw.Widget _h(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 6.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      );

  static pw.Widget _c(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2.5),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
}
