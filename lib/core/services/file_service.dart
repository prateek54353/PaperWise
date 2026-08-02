import 'dart:io';
import 'package:path/path.dart' as path;

/// Abstract file service for file operations
abstract class FileService {
  Future<File> copyFile(File source, String targetPath);
  Future<File> renameFile(File source, String newPath);
  Future<File> writeBytes(String path, List<int> bytes);
  Future<List<int>> readBytes(String path);
  Future<String> getFileName(String filePath);
  Future<String> getFileExtension(String filePath);
  String sanitizeFileName(String fileName);
}

/// Implementation of file service
class FileServiceImpl implements FileService {
  @override
  Future<File> copyFile(File source, String targetPath) async {
    return await source.copy(targetPath);
  }

  @override
  Future<File> renameFile(File source, String newPath) async {
    return await source.rename(newPath);
  }

  @override
  Future<File> writeBytes(String filePath, List<int> bytes) async {
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }

  @override
  Future<List<int>> readBytes(String filePath) async {
    final file = File(filePath);
    return await file.readAsBytes();
  }

  @override
  Future<String> getFileName(String filePath) async {
    return path.basename(filePath);
  }

  @override
  Future<String> getFileExtension(String filePath) async {
    return path.extension(filePath);
  }

  @override
  String sanitizeFileName(String fileName) {
    // Remove invalid characters for file names
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
