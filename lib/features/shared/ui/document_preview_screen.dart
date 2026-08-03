import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/theme/app_colors.dart';

class DocumentPreviewScreen extends StatelessWidget {
  final String filePath;

  const DocumentPreviewScreen({super.key, required this.filePath});

  bool get isImage =>
      filePath.endsWith('.jpg') ||
      filePath.endsWith('.jpeg') ||
      filePath.endsWith('.png');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document justificatif'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: isImage
            ? Image.file(
                File(filePath),
                fit: BoxFit.contain,
              )
            : ElevatedButton.icon(
                onPressed: () async {
                  await OpenFilex.open(filePath);
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Ouvrir le document PDF'),
              ),
      ),
    );
  }
}
