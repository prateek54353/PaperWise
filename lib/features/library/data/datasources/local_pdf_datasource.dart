import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:paperwise_pdf_maker/core/constants/app_constants.dart';
import '../models/pdf_model.dart';

abstract class PdfDataSource {
  Future<List<PdfModel>> loadPdfs();
  Future<void> deletePdf(String pdfPath);
  Future<String> downloadPdf(String pdfPath);
  Future<String> renamePdf(String pdfPath, String newName);
  Future<String> savePdfBytes(List<int> bytes, String fileName);
}

class LocalPdfDataSource implements PdfDataSource {
  LocalPdfDataSource();

  @override
  Future<List<PdfModel>> loadPdfs() async {
    try {
      final documentsDir = await pp.getApplicationDocumentsDirectory();
      final pdfDir = Directory(path.join(documentsDir.path,
          AppConstants.pdfDirectoryName, AppConstants.pdfSubdirectory));

      if (!await pdfDir.exists()) {
        return [];
      }

      final files = <File>[];
      await for (final entity in pdfDir.list(followLinks: false)) {
        if (entity is File &&
            entity.path.toLowerCase().endsWith(AppConstants.pdfExtension)) {
          files.add(entity);
        }
      }

      final pdfs = await Future.wait(files.map((file) async {
        final stat = await file.stat();
        final pageCount = await PdfModel.getPageCount(file.path);
        return PdfModel(
          path: file.path,
          name: path.basename(file.path),
          createdAt: stat.modified,
          modifiedAt: stat.modified,
          size: stat.size,
          pageCount: pageCount,
        );
      }));
      pdfs.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      return pdfs;
    } catch (e) {
      throw Exception('Failed to load PDFs: $e');
    }
  }

  @override
  Future<void> deletePdf(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete PDF: $e');
    }
  }

  @override
  Future<String> downloadPdf(String pdfPath) async {
    try {
      final downloadsDir = await pp.getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('Downloads directory not available');
      }

      final appSpecificDir = Directory(
          path.join(downloadsDir.path, AppConstants.downloadsSubdirectory));
      if (!await appSpecificDir.exists()) {
        await appSpecificDir.create(recursive: true);
      }

      final fileName = path.basename(pdfPath);
      final targetFile = File(path.join(appSpecificDir.path, fileName));

      await File(pdfPath).copy(targetFile.path);
      return targetFile.path;
    } catch (e) {
      throw Exception('Failed to download PDF: $e');
    }
  }

  @override
  Future<String> renamePdf(String pdfPath, String newName) async {
    try {
      final file = File(pdfPath);
      final dir = file.parent;
      final newFile = File('${dir.path}/$newName');
      await file.rename(newFile.path);
      return newFile.path;
    } catch (e) {
      throw Exception('Failed to rename PDF: $e');
    }
  }

  @override
  Future<String> savePdfBytes(List<int> bytes, String fileName) async {
    try {
      if (bytes.isEmpty) {
        throw Exception('Cannot save empty PDF bytes');
      }
      
      final documentsDir = await pp.getApplicationDocumentsDirectory();
      final pdfDir = Directory(path.join(documentsDir.path,
          AppConstants.pdfDirectoryName, AppConstants.pdfSubdirectory));

      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      final sanitizedFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final file = File(path.join(pdfDir.path, sanitizedFileName));
      await file.writeAsBytes(bytes);
      
      if (!await file.exists()) {
        throw Exception('Failed to create PDF file');
      }
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }
}
