import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:paperwise_pdf_maker/core/constants/app_constants.dart';
import 'package:paperwise_pdf_maker/features/library/data/services/library_file_system.dart';
import 'package:paperwise_pdf_maker/features/library/data/services/library_paths.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/folder_entity.dart';
import '../models/pdf_model.dart';

abstract class PdfDataSource {
  Future<List<PdfModel>> loadPdfs();
  Future<List<FolderEntity>> loadFolders({String parentRelative = ''});
  Future<List<FolderEntity>> loadAllFolders();
  Future<FolderEntity> createFolder(String parentRelative, String name);
  Future<FolderEntity> renameFolder(String folderRelative, String newName);
  Future<void> deleteFolder(String folderRelative, {required bool recursive});
  Future<void> moveFolder(String folderRelative, String destinationParent);
  Future<String> movePdf(String pdfRelative, String destinationFolder);
  Future<List<String>> movePdfs(
    List<String> pdfRelatives,
    String destinationFolder,
  );
  Future<void> deletePdf(String pdfPath);
  Future<String> downloadPdf(String pdfPath);
  Future<String> renamePdf(String pdfPath, String newName);
  Future<String> savePdfBytes(
    Uint8List pdfBytes,
    String fileName, {
    String folderRelative = '',
  });
  Future<void> mergePdfs(
    List<String> pdfPaths,
    String outputName, {
    String folderRelative = '',
  });
}

class LocalPdfDataSource implements PdfDataSource {
  LocalPdfDataSource({LibraryFileSystem? fileSystem})
      : _injected = fileSystem;

  final LibraryFileSystem? _injected;
  LibraryFileSystem? _cached;

  Future<LibraryFileSystem> _fs() async {
    if (_injected != null) return _injected!;
    return _cached ??= await LibraryPaths.createFileSystem();
  }

  Future<PdfModel> _toModel(File file, LibraryFileSystem fs) async {
    final stat = await file.stat();
    return PdfModel(
      path: file.path,
      name: path.basename(file.path),
      createdAt: stat.modified,
      modifiedAt: stat.modified,
      size: stat.size,
      relativePath: fs.toRelative(file.path),
    );
  }

  @override
  Future<List<PdfModel>> loadPdfs() async {
    try {
      final fs = await _fs();
      final files = await fs.listPdfs(folderRelative: '', recursive: true);
      final pdfs = await Future.wait(
        files.map((file) => _toModel(file, fs)),
      );
      pdfs.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      return pdfs;
    } catch (e) {
      throw Exception('Failed to load PDFs: $e');
    }
  }

  @override
  Future<List<FolderEntity>> loadFolders({String parentRelative = ''}) async {
    final fs = await _fs();
    final dirs = await fs.listChildFolders(parentRelative);
    final folders = <FolderEntity>[];
    for (final dir in dirs) {
      final relative = fs.toRelative(dir.path);
      folders.add(
        FolderEntity(
          relativePath: relative,
          name: path.basename(dir.path),
          documentCount: await fs.countPdfs(relative, recursive: true),
          directDocumentCount:
              await fs.countPdfs(relative, recursive: false),
        ),
      );
    }
    return folders;
  }

  @override
  Future<List<FolderEntity>> loadAllFolders() async {
    final fs = await _fs();
    final dirs = await fs.listAllFolders();
    final folders = <FolderEntity>[];
    for (final dir in dirs) {
      final relative = fs.toRelative(dir.path);
      folders.add(
        FolderEntity(
          relativePath: relative,
          name: path.basename(dir.path),
          documentCount: await fs.countPdfs(relative, recursive: true),
          directDocumentCount:
              await fs.countPdfs(relative, recursive: false),
        ),
      );
    }
    return folders;
  }

  @override
  Future<FolderEntity> createFolder(String parentRelative, String name) async {
    final fs = await _fs();
    final dir = await fs.createFolder(parentRelative, name);
    final relative = fs.toRelative(dir.path);
    return FolderEntity(
      relativePath: relative,
      name: path.basename(dir.path),
    );
  }

  @override
  Future<FolderEntity> renameFolder(
    String folderRelative,
    String newName,
  ) async {
    final fs = await _fs();
    final dir = await fs.renameFolder(folderRelative, newName);
    final relative = fs.toRelative(dir.path);
    return FolderEntity(
      relativePath: relative,
      name: path.basename(dir.path),
      documentCount: await fs.countPdfs(relative, recursive: true),
      directDocumentCount: await fs.countPdfs(relative, recursive: false),
    );
  }

  @override
  Future<void> deleteFolder(
    String folderRelative, {
    required bool recursive,
  }) async {
    final fs = await _fs();
    await fs.deleteFolder(folderRelative, recursive: recursive);
  }

  @override
  Future<void> moveFolder(
    String folderRelative,
    String destinationParent,
  ) async {
    final fs = await _fs();
    await fs.moveFolder(folderRelative, destinationParent);
  }

  @override
  Future<String> movePdf(String pdfRelative, String destinationFolder) async {
    final fs = await _fs();
    final file = await fs.movePdf(pdfRelative, destinationFolder);
    return fs.toRelative(file.path);
  }

  @override
  Future<List<String>> movePdfs(
    List<String> pdfRelatives,
    String destinationFolder,
  ) async {
    final results = <String>[];
    for (final relative in pdfRelatives) {
      results.add(await movePdf(relative, destinationFolder));
    }
    return results;
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
      final fs = await _fs();
      if (!fs.isInsideRoot(pdfPath)) {
        throw Exception('PDF is outside the PaperWise library');
      }
      final relative = fs.toRelative(pdfPath);
      final renamed = await fs.renamePdf(relative, newName);
      return renamed.path;
    } catch (e) {
      throw Exception('Failed to rename PDF: $e');
    }
  }

  @override
  Future<String> savePdfBytes(
    Uint8List pdfBytes,
    String fileName, {
    String folderRelative = '',
  }) async {
    try {
      final fs = await _fs();
      final file = await fs.saveBytes(
        pdfBytes,
        fileName,
        folderRelative: folderRelative,
      );
      return file.path;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  @override
  Future<void> mergePdfs(
    List<String> pdfPaths,
    String outputName, {
    String folderRelative = '',
  }) async {
    try {
      final mergedPdf = pw.Document();

      for (final pdfPath in pdfPaths) {
        final file = File(pdfPath);
        final pdfBytes = await file.readAsBytes();
        final pdfDoc = await pdfx.PdfDocument.openData(pdfBytes);

        for (var i = 1; i <= pdfDoc.pagesCount; i++) {
          try {
            final page = await pdfDoc.getPage(i);
            const resolutions = [3, 2, 1];
            Uint8List? pageBytes;

            for (final resolution in resolutions) {
              try {
                final pageImage = await page.render(
                  width: page.width * resolution,
                  height: page.height * resolution,
                );
                pageBytes = pageImage?.bytes;
                if (pageBytes != null && pageBytes.isNotEmpty) {
                  break;
                }
              } catch (renderError) {
                debugPrint(
                    'Render failed at ${resolution}x for page $i: $renderError');
                continue;
              }
            }

            if (pageBytes != null && pageBytes.isNotEmpty) {
              final pdfImage = pw.MemoryImage(pageBytes);
              mergedPdf.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat(
                    page.width.toDouble(),
                    page.height.toDouble(),
                  ),
                  build: (context) => pw.Image(
                    pdfImage,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              );
            }
          } catch (pageError) {
            debugPrint('Error processing page $i from $pdfPath: $pageError');
          }
        }

        await pdfDoc.close();
      }

      await savePdfBytes(
        await mergedPdf.save(),
        outputName,
        folderRelative: folderRelative,
      );
    } catch (e) {
      throw Exception('Failed to merge PDFs: $e');
    }
  }
}