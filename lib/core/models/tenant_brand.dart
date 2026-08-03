import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Identité documentaire d'un établissement (login + paramètres).
class TenantBrand {
  final String name;
  final String code;
  final String city;
  final String? phone;
  final String? address;
  final String? logoUrl;
  final String? docHeaderLine;
  final String? docFooterLine;
  final String? motto;
  final String? directorName;
  final String? schoolStatus;
  final String? drena;

  const TenantBrand({
    this.name = 'Établissement',
    this.code = '',
    this.city = '',
    this.phone,
    this.address,
    this.logoUrl,
    this.docHeaderLine,
    this.docFooterLine,
    this.motto,
    this.directorName,
    this.schoolStatus,
    this.drena,
  });

  factory TenantBrand.fromTenantMap(Map<String, dynamic>? t) {
    if (t == null) return const TenantBrand();
    return TenantBrand(
      name: t['name']?.toString() ?? 'Établissement',
      code: t['code']?.toString() ?? '',
      city: t['city']?.toString() ?? '',
      phone: t['phone']?.toString(),
      address: t['address']?.toString(),
      logoUrl: t['logoUrl']?.toString(),
      docHeaderLine: t['docHeaderLine']?.toString(),
      docFooterLine: t['docFooterLine']?.toString(),
      motto: t['motto']?.toString(),
      directorName: t['directorName']?.toString(),
      schoolStatus: t['schoolStatus']?.toString(),
      drena: t['drena']?.toString(),
    );
  }

  factory TenantBrand.fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return const TenantBrand();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return TenantBrand.fromTenantMap(m);
    } catch (_) {
      return const TenantBrand();
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'city': city,
        'phone': phone,
        'address': address,
        'logoUrl': logoUrl,
        'docHeaderLine': docHeaderLine,
        'docFooterLine': docFooterLine,
        'motto': motto,
        'directorName': directorName,
        'schoolStatus': schoolStatus,
        'drena': drena,
      };

  String toJsonString() => jsonEncode(toJson());

  TenantBrand copyWith({
    String? name,
    String? code,
    String? city,
    String? phone,
    String? address,
    String? logoUrl,
    String? docHeaderLine,
    String? docFooterLine,
    String? motto,
    String? directorName,
    String? schoolStatus,
    String? drena,
  }) =>
      TenantBrand(
        name: name ?? this.name,
        code: code ?? this.code,
        city: city ?? this.city,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        logoUrl: logoUrl ?? this.logoUrl,
        docHeaderLine: docHeaderLine ?? this.docHeaderLine,
        docFooterLine: docFooterLine ?? this.docFooterLine,
        motto: motto ?? this.motto,
        directorName: directorName ?? this.directorName,
        schoolStatus: schoolStatus ?? this.schoolStatus,
        drena: drena ?? this.drena,
      );
}

/// Helpers PDF partagés (header / footer / logo).
class SchoolBrandPdf {
  static Future<pw.ImageProvider?> loadLogo(String? url) async {
    if (url == null || !url.startsWith('https://')) return null;
    try {
      final res = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = res.data;
      if (bytes == null || bytes.isEmpty) return null;
      return pw.MemoryImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  static Future<pw.Widget> header({
    required TenantBrand brand,
    required String title,
  }) async {
    final logo = await loadLogo(brand.logoUrl);
    final headerLine = (brand.docHeaderLine != null &&
            brand.docHeaderLine!.trim().isNotEmpty)
        ? brand.docHeaderLine!
        : 'MINISTÈRE DE L\'ÉDUCATION NATIONALE ET DE L\'ALPHABÉTISATION';
    final drena = (brand.drena != null && brand.drena!.trim().isNotEmpty)
        ? brand.drena!
        : 'DRENA DE ${brand.city.toUpperCase().isEmpty ? '—' : brand.city.toUpperCase()}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null)
              pw.Container(
                width: 48,
                height: 48,
                margin: const pw.EdgeInsets.only(right: 10),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: logo != null
                    ? pw.CrossAxisAlignment.start
                    : pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(headerLine,
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold),
                      textAlign: logo != null
                          ? pw.TextAlign.left
                          : pw.TextAlign.center),
                  pw.SizedBox(height: 2),
                  pw.Text(drena,
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: logo != null
                          ? pw.TextAlign.left
                          : pw.TextAlign.center),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    brand.name.toUpperCase(),
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                    textAlign: logo != null
                        ? pw.TextAlign.left
                        : pw.TextAlign.center,
                  ),
                  if (brand.motto != null && brand.motto!.isNotEmpty)
                    pw.Text(brand.motto!,
                        style: pw.TextStyle(
                            fontSize: 8, fontStyle: pw.FontStyle.italic),
                        textAlign: logo != null
                            ? pw.TextAlign.left
                            : pw.TextAlign.center),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    [
                      if (brand.address != null && brand.address!.isNotEmpty)
                        brand.address!,
                      if (brand.city.isNotEmpty) brand.city,
                      if (brand.phone != null && brand.phone!.isNotEmpty)
                        'Tél. ${brand.phone}',
                    ].join(' — '),
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: logo != null
                        ? pw.TextAlign.left
                        : pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.8),
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget footer(TenantBrand brand) {
    final line = (brand.docFooterLine != null &&
            brand.docFooterLine!.trim().isNotEmpty)
        ? brand.docFooterLine!
        : (brand.motto != null && brand.motto!.isNotEmpty)
            ? brand.motto!
            : 'Document généré par ECOLE+';
    return pw.Column(
      children: [
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey300),
        pw.Text(line,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            textAlign: pw.TextAlign.center),
        pw.Text('Document ECOLE+',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
            textAlign: pw.TextAlign.center),
      ],
    );
  }
}
