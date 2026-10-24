import 'dart:io';
import '../../domain/entities/pdf_entity.dart';

class PdfModel {
  final String path;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int size;
  final String relativePath;
  final int pageCount;

  PdfModel({
    required this.path,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    required this.size,
    required this.relativePath,
    this.pageCount = 0,
  });

  factory PdfModel.fromEntity(PdfEntity entity) {
    return PdfModel(
      path: entity.file.path,
      name: entity.name,
      createdAt: entity.createdAt,
      modifiedAt: entity.modifiedAt,
      size: entity.size,
      relativePath: entity.relativePath,
      pageCount: entity.pageCount,
    );
  }

  PdfEntity toEntity() {
    return PdfEntity(
      file: File(path),
      name: name,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      size: size,
      relativePath: relativePath,
      pageCount: pageCount,
    );
  }
}