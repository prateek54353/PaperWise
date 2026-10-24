import 'dart:io';

import 'package:pdfx/pdfx.dart' as pdfx;

class PdfPageCountService {
  PdfPageCountService._();
  static final PdfPageCountService instance = PdfPageCountService._();

  final Map<String, int> _cache = {};

  Future<int?> getPageCount(File pdfFile) async {
    try {
      final stat = await pdfFile.stat();
      final key =
          '${pdfFile.path}_${stat.modified.millisecondsSinceEpoch}_${stat.size}';
      final cached = _cache[key];
      if (cached != null) return cached;

      final document = await pdfx.PdfDocument.openFile(pdfFile.path);
      final count = document.pagesCount;
      await document.close();
      _cache[key] = count;
      return count;
    } catch (_) {
      return null;
    }
  }
}