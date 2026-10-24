import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import 'package:paperwise_pdf_maker/features/library/application/usecases/delete_pdf_usecase.dart';
import 'package:paperwise_pdf_maker/features/library/application/usecases/load_pdfs_usecase.dart';
import 'package:paperwise_pdf_maker/features/library/application/usecases/share_pdf_usecase.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/folder_entity.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/domain/repositories/pdf_repository.dart'
    show PdfRepository, SortOption;

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

  Future<Either<Failure, List<PdfEntity>>> getPdfs() async {
    return await _loadPdfsUseCase();
  }

  Future<Either<Failure, List<FolderEntity>>> getFolders({
    String parentRelative = '',
  }) {
    return repository.loadFolders(parentRelative: parentRelative);
  }

  Future<Either<Failure, List<FolderEntity>>> getAllFolders() {
    return repository.loadAllFolders();
  }

  Future<Either<Failure, FolderEntity>> createFolder(
    String parentRelative,
    String name,
  ) {
    return repository.createFolder(parentRelative, name);
  }

  Future<Either<Failure, FolderEntity>> renameFolder(
    String folderRelative,
    String newName,
  ) {
    return repository.renameFolder(folderRelative, newName);
  }

  Future<Either<Failure, void>> deleteFolder(
    String folderRelative, {
    required bool recursive,
  }) {
    return repository.deleteFolder(folderRelative, recursive: recursive);
  }

  Future<Either<Failure, void>> moveFolder(
    String folderRelative,
    String destinationParent,
  ) {
    return repository.moveFolder(folderRelative, destinationParent);
  }

  Future<Either<Failure, List<PdfEntity>>> movePdfs(
    List<PdfEntity> pdfs,
    String destinationFolder,
  ) {
    return repository.movePdfs(pdfs, destinationFolder);
  }

  Future<Either<Failure, void>> deletePdf(PdfEntity pdf) async {
    return await _deletePdfUseCase.call(pdf);
  }

  Future<Either<Failure, void>> deletePdfs(List<PdfEntity> pdfs) async {
    return await _deletePdfUseCase.callMultiple(pdfs);
  }

  Future<Either<Failure, void>> sharePdf(PdfEntity pdf) async {
    return await _sharePdfUseCase.call(pdf);
  }

  Future<Either<Failure, PdfEntity>> downloadPdf(PdfEntity pdf) async {
    return await repository.downloadPdf(pdf);
  }

  Future<Either<Failure, PdfEntity>> renamePdf(
    PdfEntity pdf,
    String newName,
  ) async {
    return await repository.renamePdf(pdf, newName);
  }

  Future<Either<Failure, List<PdfEntity>>> searchPdfs(String query) async {
    return await repository.searchPdfs(query);
  }

  Future<Either<Failure, List<PdfEntity>>> sortPdfs(
    List<PdfEntity> pdfs,
    SortOption option,
  ) async {
    return await repository.sortPdfs(pdfs, option);
  }

  Future<Either<Failure, PdfEntity>> savePdfBytes(
    Uint8List pdfBytes,
    String fileName, {
    String folderRelative = '',
  }) async {
    return await repository.savePdfBytes(
      pdfBytes,
      fileName,
      folderRelative: folderRelative,
    );
  }

  Future<Either<Failure, PdfEntity>> mergePdfs(
    List<PdfEntity> pdfs,
    String outputName, {
    String folderRelative = '',
  }) async {
    return await repository.mergePdfs(
      pdfs,
      outputName,
      folderRelative: folderRelative,
    );
  }
}