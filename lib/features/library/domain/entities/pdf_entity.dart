import 'dart:io';

class PdfEntity {
  final File file;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int size;

  PdfEntity({
    required this.file,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    required this.size,
  });

  PdfEntity copyWith({
    File? file,
    String? name,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? size,
  }) {
    return PdfEntity(
      file: file ?? this.file,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      size: size ?? this.size,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfEntity &&
          runtimeType == other.runtimeType &&
          file.path == other.file.path &&
          name == other.name;

  @override
  int get hashCode => Object.hash(file.path, name);
}
