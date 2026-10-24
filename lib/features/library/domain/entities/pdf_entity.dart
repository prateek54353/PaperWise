import 'dart:io';

class PdfEntity {
  final File file;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int size;
  final int pageCount;

  /// Path relative to the PDF library root, using `/` separators.
  final String relativePath;

  PdfEntity({
    required this.file,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    required this.size,
    this.pageCount = 0,
    String? relativePath,
  }) : relativePath = relativePath ?? name;

  String get path => file.path;

  String get folderRelativePath {
    final separator = relativePath.lastIndexOf('/');
    if (separator <= 0) return '';
    return relativePath.substring(0, separator);
  }

  PdfEntity copyWith({
    File? file,
    String? name,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? size,
    int? pageCount,
    String? relativePath,
  }) {
    return PdfEntity(
      file: file ?? this.file,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      size: size ?? this.size,
      pageCount: pageCount ?? this.pageCount,
      relativePath: relativePath ?? this.relativePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfEntity &&
          runtimeType == other.runtimeType &&
          relativePath == other.relativePath &&
          name == other.name;

  @override
  int get hashCode => Object.hash(relativePath, name);
}