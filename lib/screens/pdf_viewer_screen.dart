import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:paperwise_pdf_maker/services/pdf_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final File pdfFile;
  const PdfViewerScreen({super.key, required this.pdfFile});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfController _pdfController;
  final PDFService _pdfService = PDFService();

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.pdfFile.path),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.pdfFile.path.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _pdfService.sharePDF(widget.pdfFile),
          ),
          PdfPageNumber(
            controller: _pdfController,
            builder: (_, state, page, pages) => Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('$page/${pages ?? 0}'),
            ),
          )
        ],
      ),
      body: PdfView(
        controller: _pdfController,
        scrollDirection: Axis.vertical,
      ),
    );
  }
}