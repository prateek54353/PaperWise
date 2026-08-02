import 'package:dartz/dartz.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import 'package:paperwise_pdf_maker/features/library/application/usecases/delete_pdf_usecase.dart';
import 'package:paperwise_pdf_maker/features/library/application/usecases/load_pdfs_usecase.dart';
import 'package:paperwise_pdf_maker/features/library/application/usecases/share_pdf_usecase.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/domain/repositories/pdf_repository.dart' show PdfRepository, SortOption;

/// Facade for library operations - orchestrates use cases
class LibraryFacade {
  final PdfRepository repository;
  late final LoadPdfsUseCase _loadPdfsUseCase;
  late final DeletePdfUseCase _deletePdfUseCase;
  late final SharePdfUseCase _sharePdfUseCase;

  LibraryFacade(this.repository) {
    _loadPdfsUseCase = LoadPdfsUseCase(repository);
    _deletePdfUseCase = DeletePdfUseCase(repository);
    _sharePdfUseCase = SharePdfUseCase(repository);
  }

  /// Load all PDFs
  Future<Either<Failure, List<PdfEntity>>> getPdfs() async {
    return await _loadPdfsUseCase();
  }

  /// Delete a single PDF
  Future<Either<Failure, void>> deletePdf(PdfEntity pdf) async {
    return await _deletePdfUseCase.call(pdf);
  }

  /// Delete multiple PDFs
  Future<Either<Failure, void>> deletePdfs(List<PdfEntity> pdfs) async {
    return await _deletePdfUseCase.callMultiple(pdfs);
  }

  /// Share a PDF
  Future<Either<Failure, void>> sharePdf(PdfEntity pdf) async {
    return await _sharePdfUseCase.call(pdf);
  }

  /// Download a PDF
  Future<Either<Failure, PdfEntity>> downloadPdf(PdfEntity pdf) async {
    return await repository.downloadPdf(pdf);
  }

  /// Rename a PDF
  Future<Either<Failure, PdfEntity>> renamePdf(PdfEntity pdf, String newName) async {
    return await repository.renamePdf(pdf, newName);
  }

  /// Search PDFs by name
  Future<Either<Failure, List<PdfEntity>>> searchPdfs(String query) async {
    return await repository.searchPdfs(query);
  }

  /// Sort PDFs
  Future<Either<Failure, List<PdfEntity>>> sortPdfs(List<PdfEntity> pdfs, SortOption option) async {
    return await repository.sortPdfs(pdfs, option);
  }
}

