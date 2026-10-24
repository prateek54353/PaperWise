import 'dart:io';

import 'package:path/path.dart' as p;

class FolderNameException implements Exception {
  FolderNameException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LibraryIoException implements Exception {
  LibraryIoException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Filesystem-backed library under a PDF root directory.
///
/// Relative paths are the stable identifiers. Absolute paths are resolved
/// against [root] and must never be persisted as the only identity.
class LibraryFileSystem {
  LibraryFileSystem(this.root);

  final Directory root;

  static const _invalidNamePattern = r'[<>:"/\\|?*]';
  static const _reservedNames = {
    'con',
    'prn',
    'aux',
    'nul',
    'com1',
    'lpt1',
  };

  Future<Directory> ensureRoot() async {
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  static String? validateFolderName(String rawName) {
    final name = rawName.trim();
    if (name.isEmpty) {
      return 'Folder name cannot be empty';
    }
    if (name == '.' || name == '..') {
      return 'That folder name is not allowed';
    }
    if (name.startsWith('.')) {
      return 'Folder names cannot start with a period';
    }
    if (RegExp(_invalidNamePattern).hasMatch(name)) {
      return 'Folder name contains invalid characters';
    }
    if (_reservedNames.contains(name.toLowerCase())) {
      return 'That folder name is reserved by the system';
    }
    if (name.length > 80) {
      return 'Folder name is too long';
    }
    return null;
  }

  String sanitizeFileName(String fileName) {
    final trimmed = fileName.trim();
    final sanitized = trimmed.replaceAll(RegExp(_invalidNamePattern), '_');
    return sanitized.isEmpty ? 'document.pdf' : sanitized;
  }

  Directory directoryFor(String relativePath) {
    if (relativePath.isEmpty) return root;
    final resolved = Directory(p.normalize(p.join(root.path, relativePath)));
    _assertInsideRoot(resolved.path);
    return resolved;
  }

  File fileFor(String relativePath) {
    final resolved = File(p.normalize(p.join(root.path, relativePath)));
    _assertInsideRoot(resolved.path);
    return resolved;
  }

  String toRelative(String absolutePath) {
    final relative = p.relative(absolutePath, from: root.path);
    if (relative == '.' || relative == './') return '';
    return relative.replaceAll('\\', '/');
  }

  bool isInsideRoot(String absolutePath) {
    final normalizedRoot = p.normalize(root.path);
    final normalized = p.normalize(absolutePath);
    return normalized == normalizedRoot ||
        p.isWithin(normalizedRoot, normalized);
  }

  Future<List<Directory>> listAllFolders() async {
    await ensureRoot();
    final folders = <Directory>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue;
        folders.add(entity);
      }
    }
    folders.sort(
      (a, b) => toRelative(a.path)
          .toLowerCase()
          .compareTo(toRelative(b.path).toLowerCase()),
    );
    return folders;
  }

  Future<List<Directory>> listChildFolders(String parentRelative) async {
    await ensureRoot();
    final dir = directoryFor(parentRelative);
    if (!await dir.exists()) return [];

    final folders = <Directory>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue;
        folders.add(entity);
      }
    }
    folders.sort(
      (a, b) => p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase()),
    );
    return folders;
  }

  Future<List<File>> listPdfs({
    required String folderRelative,
    bool recursive = false,
  }) async {
    await ensureRoot();
    final dir = directoryFor(folderRelative);
    if (!await dir.exists()) return [];

    final files = <File>[];
    if (recursive) {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && _isPdf(entity.path)) {
          files.add(entity);
        }
      }
    } else {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File && _isPdf(entity.path)) {
          files.add(entity);
        }
      }
    }
    return files;
  }

  Future<int> countPdfs(String folderRelative, {bool recursive = true}) async {
    final files =
        await listPdfs(folderRelative: folderRelative, recursive: recursive);
    return files.length;
  }

  Future<Directory> createFolder(String parentRelative, String rawName) async {
    final error = validateFolderName(rawName);
    if (error != null) throw FolderNameException(error);

    await ensureRoot();
    final parent = directoryFor(parentRelative);
    if (!await parent.exists()) {
      throw LibraryIoException('Parent folder is missing');
    }

    final name = rawName.trim();
    final target = Directory(p.join(parent.path, name));
    _assertInsideRoot(target.path);
    if (await target.exists()) {
      throw FolderNameException('A folder named "$name" already exists');
    }
    return target.create(recursive: false);
  }

  Future<Directory> renameFolder(
    String folderRelative,
    String rawNewName,
  ) async {
    if (folderRelative.isEmpty) {
      throw FolderNameException('Cannot rename the library root');
    }
    final error = validateFolderName(rawNewName);
    if (error != null) throw FolderNameException(error);

    final source = directoryFor(folderRelative);
    if (!await source.exists()) {
      throw LibraryIoException('Folder no longer exists');
    }

    final parent = source.parent;
    final newName = rawNewName.trim();
    final target = Directory(p.join(parent.path, newName));
    _assertInsideRoot(target.path);

    if (p.equals(source.path, target.path)) return source;
    if (await target.exists()) {
      throw FolderNameException('A folder named "$newName" already exists');
    }

    return source.rename(target.path);
  }

  Future<Directory> moveFolder(
    String folderRelative,
    String destinationParentRelative,
  ) async {
    if (folderRelative.isEmpty) {
      throw FolderNameException('Cannot move the library root');
    }
    final source = directoryFor(folderRelative);
    if (!await source.exists()) {
      throw LibraryIoException('Folder no longer exists');
    }

    final destParent = directoryFor(destinationParentRelative);
    if (!await destParent.exists()) {
      throw LibraryIoException('Destination folder is missing');
    }

    if (p.equals(source.path, destParent.path) ||
        p.isWithin(source.path, destParent.path)) {
      throw FolderNameException('Cannot move a folder into itself');
    }

    final name = p.basename(source.path);
    var target = Directory(p.join(destParent.path, name));
    _assertInsideRoot(target.path);
    if (await target.exists()) {
      throw FolderNameException(
        'A folder named "$name" already exists in the destination',
      );
    }

    try {
      return await source.rename(target.path);
    } on FileSystemException {
      await _copyDirectory(source, target);
      if (!await target.exists()) {
        throw LibraryIoException('Could not move folder');
      }
      await source.delete(recursive: true);
      return target;
    }
  }

  Future<void> deleteFolder(
    String folderRelative, {
    required bool recursive,
  }) async {
    if (folderRelative.isEmpty) {
      throw FolderNameException('Cannot delete the library root');
    }
    final dir = directoryFor(folderRelative);
    if (!await dir.exists()) return;

    if (!recursive) {
      final hasChildren = await dir.list(followLinks: false).isEmpty == false;
      if (hasChildren) {
        throw FolderNameException(
          'Folder is not empty. Confirm deletion of its contents first.',
        );
      }
      await dir.delete();
      return;
    }

    await dir.delete(recursive: true);
  }

  Future<File> renamePdf(String pdfRelative, String rawNewName) async {
    final source = fileFor(pdfRelative);
    if (!await source.exists()) {
      throw LibraryIoException('The PDF is no longer on this device');
    }

    var newName = sanitizeFileName(rawNewName);
    if (!newName.toLowerCase().endsWith('.pdf')) {
      newName = '$newName.pdf';
    }
    if (newName.toLowerCase() == '.pdf') {
      throw FolderNameException('Enter a valid file name');
    }

    final targetPath = p.join(source.parent.path, newName);
    _assertInsideRoot(targetPath);
    if (p.equals(source.path, targetPath)) return source;
    if (await File(targetPath).exists()) {
      throw FolderNameException('A PDF named "$newName" already exists');
    }

    return _moveFileSafely(source, targetPath);
  }

  Future<File> movePdf(String pdfRelative, String destinationFolderRelative) async {
    final source = fileFor(pdfRelative);
    if (!await source.exists()) {
      throw LibraryIoException('The PDF is no longer on this device');
    }

    final destDir = directoryFor(destinationFolderRelative);
    if (!await destDir.exists()) {
      throw LibraryIoException('Destination folder is missing');
    }

    if (p.equals(source.parent.path, destDir.path)) {
      return source;
    }

    final uniqueName =
        await uniqueFileName(destDir, p.basename(source.path));
    final targetPath = p.join(destDir.path, uniqueName);
    return _moveFileSafely(source, targetPath);
  }

  Future<List<File>> movePdfs(
    List<String> pdfRelatives,
    String destinationFolderRelative,
  ) async {
    final moved = <File>[];
    for (final relative in pdfRelatives) {
      moved.add(await movePdf(relative, destinationFolderRelative));
    }
    return moved;
  }

  Future<File> saveBytes(
    List<int> bytes,
    String fileName, {
    String folderRelative = '',
  }) async {
    await ensureRoot();
    final dir = directoryFor(folderRelative);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final unique = await uniqueFileName(dir, sanitizeFileName(fileName));
    final file = File(p.join(dir.path, unique));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<String> uniqueFileName(Directory dir, String fileName) async {
    final sanitized = sanitizeFileName(fileName);
    final ext = p.extension(sanitized);
    final base = p.basenameWithoutExtension(sanitized);
    var candidate = sanitized;
    var index = 1;
    while (await File(p.join(dir.path, candidate)).exists()) {
      candidate = '$base ($index)$ext';
      index += 1;
    }
    return candidate;
  }

  Future<File> _moveFileSafely(File source, String targetPath) async {
    _assertInsideRoot(targetPath);
    final originalExists = await source.exists();
    if (!originalExists) {
      throw LibraryIoException('The PDF is no longer on this device');
    }
    final originalLength = await source.length();

    try {
      return await source.rename(targetPath);
    } on FileSystemException {
      try {
        await source.copy(targetPath);
        final dest = File(targetPath);
        if (!await dest.exists() || await dest.length() != originalLength) {
          if (await dest.exists()) {
            await dest.delete();
          }
          throw LibraryIoException(
            'Move failed and the original file was kept',
          );
        }
        try {
          await source.delete();
        } catch (_) {
          // Duplicate is preferable to data loss.
        }
        return dest;
      } catch (e) {
        final dest = File(targetPath);
        if (await dest.exists() && await dest.length() != originalLength) {
          try {
            await dest.delete();
          } catch (_) {}
        }
        if (!await source.exists()) {
          throw LibraryIoException(
            'Move failed and the original file could not be verified',
          );
        }
        throw LibraryIoException(
          'Move failed and the original file was kept',
        );
      }
    }
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: false, followLinks: false)) {
      final name = p.basename(entity.path);
      if (entity is File) {
        await entity.copy(p.join(target.path, name));
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(p.join(target.path, name)));
      }
    }
  }

  bool _isPdf(String filePath) => p.extension(filePath).toLowerCase() == '.pdf';

  void _assertInsideRoot(String absolutePath) {
    if (!isInsideRoot(absolutePath)) {
      throw LibraryIoException('Path is outside the PaperWise library');
    }
  }
}