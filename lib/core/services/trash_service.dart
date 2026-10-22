import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class TrashService {
  static const String _trashDir = 'trash';
  static final Map<String, File> _cachedFiles = {};
  static final Map<String, File> _trashFiles = {};
  static final Map<String, Timer> _undoTimers = {};

  /// Get the trash directory
  static Future<Directory> getTrashDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final trashDir = Directory(path.join(appDir.path, _trashDir));
    
    if (!await trashDir.exists()) {
      await trashDir.create(recursive: true);
    }
    
    return trashDir;
  }

  /// Move a file to trash instead of permanently deleting it
  static Future<String> moveToTrash(File file) async {
    final trashDir = await getTrashDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(file.path);
    final trashFileName = '${timestamp}_$extension';
    final trashPath = path.join(trashDir.path, trashFileName);
    
    // Cache the original file for potential undo
    _cachedFiles[trashPath] = file;
    
    // Copy file to trash
    await file.copy(trashPath);
    
    // Store the trash file reference
    _trashFiles[file.path] = File(trashPath);
    
    // Set timer to permanently delete after 4 seconds (undo timeout)
    _undoTimers[file.path] = Timer(const Duration(seconds: 4), () {
      permanentlyDelete(file.path);
    });
    
    return trashPath;
  }

  /// Restore a file from trash
  static Future<bool> restoreFromTrash(String originalPath) async {
    final trashPath = _trashFiles[originalPath];
    
    if (trashPath == null || !await trashPath.exists()) {
      return false;
    }
    
    // Cancel the undo timer
    _undoTimers[originalPath]?.cancel();
    _undoTimers.remove(originalPath);
    
    try {
      // Copy back to original location
      await trashPath.copy(originalPath);
      
      // Delete from trash
      await trashPath.delete();
      
      // Clean up references
      _trashFiles.remove(originalPath);
      _cachedFiles.remove(trashPath.path);
      
      // Also clean up original file reference from cache
      _cachedFiles.removeWhere((key, value) => value.path == originalPath);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Permanently delete a file from trash (call this after undo timeout)
  static Future<void> permanentlyDelete(String originalPath) async {
    final trashPath = _trashFiles[originalPath];
    
    // Cancel the undo timer if still running
    _undoTimers[originalPath]?.cancel();
    _undoTimers.remove(originalPath);
    
    if (trashPath != null && await trashPath.exists()) {
      await trashPath.delete();
      _trashFiles.remove(originalPath);
      _cachedFiles.remove(trashPath.path);
    }
    
    // Clean up original file reference from cache to prevent memory leaks
    _cachedFiles.removeWhere((key, value) => value.path == originalPath);
  }

  /// Empty the trash (call this on app startup)
  static Future<void> emptyTrash() async {
    // Cancel all pending timers
    for (final timer in _undoTimers.values) {
      timer.cancel();
    }
    _undoTimers.clear();
    
    final trashDir = await getTrashDirectory();
    
    if (await trashDir.exists()) {
      await for (final entity in trashDir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
    
    _trashFiles.clear();
    _cachedFiles.clear();
  }

  /// Clean up stale entries from internal maps (call periodically to prevent memory leaks)
  /// This removes entries where the trash file no longer exists
  static Future<void> cleanupStaleEntries() async {
    // Clean up trash files map
    final staleTrashKeys = <String>[];
    for (final entry in _trashFiles.entries) {
      if (!await entry.value.exists()) {
        staleTrashKeys.add(entry.key);
      }
    }
    for (final key in staleTrashKeys) {
      _trashFiles.remove(key);
      _undoTimers[key]?.cancel();
      _undoTimers.remove(key);
    }
    
    // Clean up cached files map
    final staleCacheKeys = <String>[];
    for (final entry in _cachedFiles.entries) {
      if (!await entry.value.exists()) {
        staleCacheKeys.add(entry.key);
      }
    }
    for (final key in staleCacheKeys) {
      _cachedFiles.remove(key);
    }
  }

  /// Get trash file path for a given original path
  static String? getTrashPath(String originalPath) {
    return _trashFiles[originalPath]?.path;
  }
}