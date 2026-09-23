import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import '../../domain/entities/pdf_entity.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../datasources/local_pdf_datasource.dart';

class PdfRepositoryImpl implements PdfRepository {
  final PdfDataSource dataSource;

  PdfRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<PdfEntity>>> loadPdfs() async {
    try {
      final models = await dataSource.loadPdfs();
      return Right(models.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(PdfFailure('Failed to load PDFs: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePdf(PdfEntity pdf) async {
    try {
      await dataSource.deletePdf(pdf.file.path);
      return const Right(null);
    } catch (e) {
      return Left(PdfFailure('Failed to delete PDF: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePdfs(List<PdfEntity> pdfs) async {
    try {
      for (final pdf in pdfs) {
        await dataSource.deletePdf(pdf.file.path);
      }
      return const Right(null);
    } catch (e) {
      return Left(PdfFailure('Failed to delete PDFs: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sharePdf(PdfEntity pdf) async {
    try {
      await Share.shareXFiles(
        [XFile(pdf.file.path)],
        subject: pdf.name,
      );
      return const Right(null);
    } catch (e) {
      return Left(PdfFailure('Failed to share PDF: $e'));
    }
  }

  @override
  Future<Either<Failure, PdfEntity>> downloadPdf(PdfEntity pdf) async {
    try {
      final newPath = await dataSource.downloadPdf(pdf.file.path);
      final updatedPdf = pdf.copyWith(file: File(newPath));
      return Right(updatedPdf);
    } catch (e) {
      return Left(PdfFailure('Failed to download PDF: $e'));
    }
  }

  @override
  Future<Either<Failure, PdfEntity>> renamePdf(PdfEntity pdf, String newName) async {
    try {
      final newPath = await dataSource.renamePdf(pdf.file.path, newName);
      final updatedPdf = pdf.copyWith(
        file: File(newPath),
        name: newName,
      );
      return Right(updatedPdf);
    } catch (e) {
      return Left(PdfFailure('Failed to rename PDF: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PdfEntity>>> searchPdfs(String query) async {
    try {
      final allPdfs = await loadPdfs();
      final Either<Failure, List<PdfEntity>> result = allPdfs.fold(
        (failure) => Left(failure),
        (pdfs) {
          final filtered = pdfs.where((pdf) {
            return pdf.name.toLowerCase().contains(query.toLowerCase());
          }).toList();
          return Right(filtered);
        },
      );
      return result;
    } catch (e) {
      return Left(PdfFailure('Failed to search PDFs: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PdfEntity>>> sortPdfs(List<PdfEntity> pdfs, SortOption option) async {
    try {
      final sorted = List<PdfEntity>.from(pdfs);
      
      switch (option) {
        case SortOption.name:
          sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case SortOption.date:
          sorted.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
          break;
      }
      
      return Right(sorted);
    } catch (e) {
      return Left(PdfFailure('Failed to sort PDFs: $e'));
    }
  }

  @override
  Future<Either<Failure, PdfEntity>> savePdfBytes(Uint8List pdfBytes, String fileName) async {
    try {
      final filePath = await dataSource.savePdfBytes(pdfBytes, fileName);
      final file = File(filePath);
      final modifiedTime = file.lastModifiedSync();
      final pdfEntity = PdfEntity(
        file: file,
        name: fileName,
        size: file.lengthSync(),
        pageCount: 1, // Placeholder, could be determined by parsing PDF
        createdAt: modifiedTime,
        modifiedAt: modifiedTime,
      );
      return Right(pdfEntity);
    } catch (e) {
      return Left(PdfFailure('Failed to save PDF: $e'));
    }
  }

  @override
  Future<Either<Failure, PdfEntity>> mergePdfs(List<PdfEntity> pdfs, String outputName) async {
    try {
      await dataSource.mergePdfs(pdfs.map((p) => p.file.path).toList(), outputName);
      // Just return a dummy entity - the library will be refreshed by the provider
      final documentsDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${documentsDir.path}/PaperWise/PDFs');
      final outputFile = File('${pdfDir.path}/$outputName');
      final pdfEntity = PdfEntity(
        file: outputFile,
        name: outputName,
        size: outputFile.lengthSync(),
        pageCount: 1,
        createdAt: outputFile.lastModifiedSync(),
        modifiedAt: outputFile.lastModifiedSync(),
      );
      return Right(pdfEntity);
    } catch (e) {
      return Left(PdfFailure('Failed to merge PDFs: $e'));
    }
  }
}
