import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import '../entities/folder_entity.dart';
import '../entities/pdf_entity.dart';

enum SortOption { date, name }

abstract class PdfRepository {
  Future<Either<Failure, List<PdfEntity>>> loadPdfs();
  Future<Either<Failure, List<FolderEntity>>> loadFolders({
    String parentRelative = '',
  });
  Future<Either<Failure, List<FolderEntity>>> loadAllFolders();
  Future<Either<Failure, FolderEntity>> createFolder(
    String parentRelative,
    String name,
  );
  Future<Either<Failure, FolderEntity>> renameFolder(
    String folderRelative,
    String newName,
  );
  Future<Either<Failure, void>> deleteFolder(
    String folderRelative, {
    required bool recursive,
  });
  Future<Either<Failure, void>> moveFolder(
    String folderRelative,
    String destinationParent,
  );
  Future<Either<Failure, List<PdfEntity>>> movePdfs(
    List<PdfEntity> pdfs,
    String destinationFolder,
  );
  Future<Either<Failure, void>> deletePdf(PdfEntity pdf);
  Future<Either<Failure, void>> deletePdfs(List<PdfEntity> pdfs);
  Future<Either<Failure, void>> sharePdf(PdfEntity pdf);
  Future<Either<Failure, PdfEntity>> downloadPdf(PdfEntity pdf);
  Future<Either<Failure, PdfEntity>> renamePdf(PdfEntity pdf, String newName);
  Future<Either<Failure, List<PdfEntity>>> searchPdfs(String query);
  Future<Either<Failure, List<PdfEntity>>> sortPdfs(
    List<PdfEntity> pdfs,
    SortOption option,
  );
  Future<Either<Failure, PdfEntity>> savePdfBytes(
    Uint8List pdfBytes,
    String fileName, {
    String folderRelative = '',
  });
  Future<Either<Failure, PdfEntity>> mergePdfs(
    List<PdfEntity> pdfs,
    String outputName, {
    String folderRelative = '',
  });
}