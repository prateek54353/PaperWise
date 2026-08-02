import 'dart:io';
import '../../domain/entities/pdf_entity.dart';

class PdfModel {
  final String path;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int size;

  PdfModel({
    required this.path,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    required this.size,
  });

  // Convert from entity
  factory PdfModel.fromEntity(PdfEntity entity) {
    return PdfModel(
      path: entity.file.path,
      name: entity.name,
      createdAt: entity.createdAt,
      modifiedAt: entity.modifiedAt,
      size: entity.size,
    );
  }

  // Convert to entity
  PdfEntity toEntity() {
    return PdfEntity(
      file: File(path),
      name: name,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      size: size,
    );
  }

  PdfModel copyWith({
    String? path,
    String? name,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? size,
  }) {
    return PdfModel(
      path: path ?? this.path,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      size: size ?? this.size,
    );
  }
}
