import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

class PdfThumbnailService {
  static const double _thumbnailWidth = 200.0;
  static const double _thumbnailHeight = 280.0;

  Future<File?> getThumbnailFile(File pdfFile) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final thumbnailDir = Directory(path.join(cacheDir.path, 'pdf_thumbnails'));
      
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      // Generate a unique filename based on PDF path and modification time
      final pdfStat = await pdfFile.stat();
      final thumbnailName = '${pdfFile.path.hashCode}_${pdfStat.modified.millisecondsSinceEpoch}.jpg';
      final thumbnailPath = path.join(thumbnailDir.path, thumbnailName);
      final thumbnailFile = File(thumbnailPath);

      // Return cached thumbnail if it exists
      if (await thumbnailFile.exists()) {
        return thumbnailFile;
      }

      // Generate new thumbnail
      final thumbnailBytes = await _generateThumbnail(pdfFile);
      if (thumbnailBytes == null) return null;

      await thumbnailFile.writeAsBytes(thumbnailBytes);
      return thumbnailFile;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> _generateThumbnail(File pdfFile) async {
    try {
      final pdfBytes = await pdfFile.readAsBytes();
      final pdfDoc = await pdfx.PdfDocument.openData(pdfBytes);

      if (pdfDoc.pagesCount == 0) {
        await pdfDoc.close();
        return null;
      }

      final page = await pdfDoc.getPage(1);
      final pageImage = await page.render(
        width: _thumbnailWidth,
        height: _thumbnailHeight,
      );

      await pdfDoc.close();
      return pageImage?.bytes;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final thumbnailDir = Directory(path.join(cacheDir.path, 'pdf_thumbnails'));
      
      if (await thumbnailDir.exists()) {
        await thumbnailDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore cache clear errors
    }
  }
}