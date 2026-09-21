import 'dart:io';
import 'package:pdfx/pdfx.dart';
import '../../domain/entities/pdf_entity.dart';

class PdfModel {
  final String path;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int size;
  final int pageCount;

  PdfModel({
    required this.path,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    required this.size,
    this.pageCount = 1,
  });

  // Convert from entity
  factory PdfModel.fromEntity(PdfEntity entity) {
    return PdfModel(
      path: entity.file.path,
      name: entity.name,
      createdAt: entity.createdAt,
      modifiedAt: entity.modifiedAt,
      size: entity.size,
      pageCount: entity.pageCount,
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
      pageCount: pageCount,
    );
  }

  PdfModel copyWith({
    String? path,
    String? name,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? size,
    int? pageCount,
  }) {
    return PdfModel(
      path: path ?? this.path,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      size: size ?? this.size,
      pageCount: pageCount ?? this.pageCount,
    );
  }

  // Get page count from PDF file
  static Future<int> getPageCount(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final pdfDoc = await PdfDocument.openData(bytes);
      return pdfDoc.pagesCount;
    } catch (e) {
      return 1; // Default to 1 if we can't read the page count
    }
  }
}
