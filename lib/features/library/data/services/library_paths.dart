import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:paperwise_pdf_maker/core/constants/app_constants.dart';
import 'package:paperwise_pdf_maker/features/library/data/services/library_file_system.dart';

class LibraryPaths {
  LibraryPaths._();

  /// App-private documents directory used on Android, iOS, and desktop.
  static Future<Directory> documentsRoot() async {
    return getApplicationDocumentsDirectory();
  }

  /// `{documents}/Paperwise/PDF` — existing PaperWise library root.
  static Future<Directory> pdfRoot() async {
    final documents = await documentsRoot();
    return Directory(
      p.join(
        documents.path,
        AppConstants.pdfDirectoryName,
        AppConstants.pdfSubdirectory,
      ),
    );
  }

  static Future<LibraryFileSystem> createFileSystem() async {
    final root = await pdfRoot();
    final fs = LibraryFileSystem(root);
    await fs.ensureRoot();
    return fs;
  }
}