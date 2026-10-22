import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

class PdfThumbnailService {
  static const double _thumbnailWidth = 200.0;
  static const double _thumbnailHeight = 280.0;
  static const int _renderScale = 2; // Render at 2x for better quality then downscale
  static const int maxCacheSizeMB = 50;
  static const int maxCacheAgeDays = 30;

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
      // Render at higher resolution for better quality
      final pageImage = await page.render(
        width: _thumbnailWidth * _renderScale,
        height: _thumbnailHeight * _renderScale,
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

  /// Clean up old thumbnails based on age and size
  Future<void> cleanupCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final thumbnailDir = Directory(path.join(cacheDir.path, 'pdf_thumbnails'));
      
      if (!await thumbnailDir.exists()) return;
      
      final now = DateTime.now();
      int totalSize = 0;
      final files = <File>[];
      
      // Collect all files with their stats
      await for (final entity in thumbnailDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);
          
          // Delete files older than maxCacheAgeDays
          if (age.inDays > maxCacheAgeDays) {
            try {
              await entity.delete();
            } catch (e) {
              debugPrint('Failed to delete old thumbnail: ${entity.path}');
            }
          } else {
            totalSize += stat.size;
            files.add(entity);
          }
        }
      }
      
      // If over size limit, delete oldest files (LRU)
      final maxSizeBytes = maxCacheSizeMB * 1024 * 1024;
      if (totalSize > maxSizeBytes) {
        // Get stats for all files first
        final fileStats = <File, FileStat>{};
        for (final file in files) {
          try {
            fileStats[file] = await file.stat();
          } catch (e) {
            // Skip files we can't stat
          }
        }
        
        // Sort by modification time (oldest first)
        final sortedFiles = fileStats.entries.toList()
          ..sort((a, b) => a.value.modified.compareTo(b.value.modified));
        
        // Delete oldest files until under limit
        for (final entry in sortedFiles) {
          if (totalSize <= maxSizeBytes) break;
          final file = entry.key;
          final stat = entry.value;
          try {
            await file.delete();
            totalSize -= stat.size;
          } catch (e) {
            debugPrint('Failed to delete thumbnail for size cleanup: ${file.path}');
          }
        }
      }
      
      debugPrint('Thumbnail cache cleanup complete. Size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');
    } catch (e) {
      debugPrint('Error during thumbnail cache cleanup: $e');
    }
  }
}