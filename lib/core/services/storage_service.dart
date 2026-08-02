import 'dart:io';
import 'package:path_provider/path_provider.dart' as pp;

/// Abstract storage service for file system operations
abstract class StorageService {
  Future<String> getApplicationDocumentsDirectory();
  Future<String> getTemporaryDirectory();
  Future<String> getDownloadsDirectory();
  Future<Directory> createDirectory(String path);
  Future<bool> directoryExists(String path);
  Future<bool> fileExists(String path);
  Future<void> deleteFile(String path);
  Future<void> deleteDirectory(String path);
}

/// Implementation of storage service using path_provider
class StorageServiceImpl implements StorageService {
  @override
  Future<String> getApplicationDocumentsDirectory() async {
    final dir = await pp.getApplicationDocumentsDirectory();
    return dir.path;
  }

  @override
  Future<String> getTemporaryDirectory() async {
    final dir = await pp.getTemporaryDirectory();
    return dir.path;
  }

  @override
  Future<String> getDownloadsDirectory() async {
    final dir = await pp.getDownloadsDirectory();
    return dir?.path ?? '';
  }

  @override
  Future<Directory> createDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<bool> directoryExists(String dirPath) async {
    return await Directory(dirPath).exists();
  }

  @override
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  @override
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> deleteDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
