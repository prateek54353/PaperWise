import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:paperwise_pdf_maker/models/app_settings.dart';
import 'package:paperwise_pdf_maker/models/page_size_mode.dart';

class PDFService {
  /// Gets the default save directory for PDFs
  Future<String> getDefaultPdfDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(path.join(documentsDir.path, 'Paperwise', 'PDF'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir.path;
  }

  /// Gets the default save directory for images
  Future<String> getDefaultImageDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(path.join(documentsDir.path, 'Paperwise', 'Images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir.path;
  }

  /// Creates a PDF from a list of images with the specified page size mode
  Future<File> createPdfFromImages(
    List<File> images,
    String fileName, {
    PageSizeMode pageSizeMode = PageSizeMode.a4,
    AppSettings? settings,
  }) async {
    try {
      final pdf = pw.Document();

      // Define standard page formats
      final Map<PageSizeMode, PdfPageFormat> formatMap = {
        PageSizeMode.a4: PdfPageFormat.a4,
        PageSizeMode.letter: PdfPageFormat.letter,
        PageSizeMode.legal: PdfPageFormat.legal,
      };

      for (var image in images) {
        final imageBytes = await image.readAsBytes();
        final pdfImage = pw.MemoryImage(imageBytes);

        // Determine page format based on mode
        PdfPageFormat pageFormat;
        if (pageSizeMode == PageSizeMode.fit) {
          // Create a custom page size that matches the image dimensions
          pageFormat = PdfPageFormat(
            pdfImage.width!.toDouble(),
            pdfImage.height!.toDouble(),
            marginAll: 0,
          );
        } else {
          // Use standard format from map, defaulting to A4 if not found
          pageFormat = formatMap[pageSizeMode] ?? PdfPageFormat.a4;
        }

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (context) => pw.Center(
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
        );
      }

      // Get save location (always use default)
      final saveLocation = await getDefaultPdfDirectory();

      // Ensure valid filename
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final file = File(path.join(saveLocation, sanitizedFileName));
      
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      debugPrint('Error creating PDF: $e');
      rethrow;
    }
  }

  /// Downloads a PDF to the Downloads directory
  Future<File> downloadPdf(File pdfFile) async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('Downloads directory not available');
      }

      final fileName = path.basename(pdfFile.path);
      final targetFile = File(path.join(downloadsDir.path, fileName));
      
      // Copy the file to downloads
      await pdfFile.copy(targetFile.path);
      return targetFile;
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      rethrow;
    }
  }

  /// Shares a PDF file using the system share sheet
  Future<void> sharePDF(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: path.basename(pdfFile.path),
      );
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      rethrow;
    }
  }

  /// Saves an image to the default images directory
  Future<File> saveImage(File imageFile) async {
    try {
      final imageDir = await getDefaultImageDirectory();
      final originalName = path.basenameWithoutExtension(imageFile.path);
      final extension = path.extension(imageFile.path);
      
      // Add timestamp to avoid overwriting
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${originalName}_$timestamp$extension';
      
      final targetFile = File(path.join(imageDir, fileName));
      
      // Copy the image to the target location
      return await imageFile.copy(targetFile.path);
    } catch (e) {
      debugPrint('Error saving image: $e');
      rethrow;
    }
  }
}