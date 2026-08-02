import 'dart:io';
import 'package:dartz/dartz.dart';
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
      return allPdfs.fold(
        (failure) => Left(failure),
        (pdfs) {
          final filtered = pdfs.where((pdf) {
            return pdf.name.toLowerCase().contains(query.toLowerCase());
          }).toList();
          return Right(filtered);
        },
      );
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
}
