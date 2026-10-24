import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import '../../domain/entities/folder_entity.dart';
import '../../domain/entities/pdf_entity.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../datasources/local_pdf_datasource.dart';

class PdfRepositoryImpl implements PdfRepository {
  final PdfDataSource dataSource;

  PdfRepositoryImpl(this.dataSource);

  Failure _mapError(Object e, String fallback) {
    final message = e.toString();
    if (message.contains('already exists') ||
        message.contains('invalid') ||
        message.contains('cannot be empty') ||
        message.contains('not allowed') ||
        message.contains('reserved') ||
        message.contains('too long') ||
        message.contains('into itself') ||
        message.contains('library root')) {
      return ValidationFailure(message, userFriendlyMessage: message);
    }
    if (message.contains('permission') || message.contains('Permission')) {
      return PermissionFailure(message, userFriendlyMessage: message);
    }
    return FileSystemFailure(
      '$fallback: $e',
      userFriendlyMessage: fallback,
    );
  }

  @override
  Future<Either<Failure, List<PdfEntity>>> loadPdfs() async {
    try {
      final models = await dataSource.loadPdfs();
      return Right(models.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(_mapError(e, 'Failed to load PDFs'));
    }
  }

  @override
  Future<Either<Failure, List<FolderEntity>>> loadFolders({
    String parentRelative = '',
  }) async {
    try {
      return Right(await dataSource.loadFolders(parentRelative: parentRelative));
    } catch (e) {
      return Left(_mapError(e, 'Failed to load folders'));
    }
  }

  @override
  Future<Either<Failure, List<FolderEntity>>> loadAllFolders() async {
    try {
      return Right(await dataSource.loadAllFolders());
    } catch (e) {
      return Left(_mapError(e, 'Failed to load folders'));
    }
  }

  @override
  Future<Either<Failure, FolderEntity>> createFolder(
    String parentRelative,
    String name,
  ) async {
    try {
      return Right(await dataSource.createFolder(parentRelative, name));
    } catch (e) {
      return Left(_mapError(e, 'Failed to create folder'));
    }
  }

  @override
  Future<Either<Failure, FolderEntity>> renameFolder(
    String folderRelative,
    String newName,
  ) async {
    try {
      return Right(await dataSource.renameFolder(folderRelative, newName));
    } catch (e) {
      return Left(_mapError(e, 'Failed to rename folder'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFolder(
    String folderRelative, {
    required bool recursive,
  }) async {
    try {
      await dataSource.deleteFolder(folderRelative, recursive: recursive);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e, 'Failed to delete folder'));
    }
  }

  @override
  Future<Either<Failure, void>> moveFolder(
    String folderRelative,
    String destinationParent,
  ) async {
    try {
      await dataSource.moveFolder(folderRelative, destinationParent);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e, 'Failed to move folder'));
    }
  }

  @override
  Future<Either<Failure, List<PdfEntity>>> movePdfs(
    List<PdfEntity> pdfs,
    String destinationFolder,
  ) async {
    try {
      await dataSource.movePdfs(
        pdfs.map((pdf) => pdf.relativePath).toList(),
        destinationFolder,
      );
      final loaded = await loadPdfs();
      return loaded;
    } catch (e) {
      return Left(_mapError(e, 'Failed to move PDFs'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePdf(PdfEntity pdf) async {
    try {
      await dataSource.deletePdf(pdf.file.path);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e, 'Failed to delete PDF'));
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
      return Left(_mapError(e, 'Failed to delete PDFs'));
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
      return Left(_mapError(e, 'Failed to download PDF'));
    }
  }

  @override
  Future<Either<Failure, PdfEntity>> renamePdf(
    PdfEntity pdf,
    String newName,
  ) async {
    try {
      final newPath = await dataSource.renamePdf(pdf.file.path, newName);
      final updatedPdf = pdf.copyWith(
        file: File(newPath),
        name: path.basename(newPath),
        relativePath: pdf.folderRelativePath.isEmpty
            ? path.basename(newPath)
            : '${pdf.folderRelativePath}/${path.basename(newPath)}',
      );
      return Right(updatedPdf);
    } catch (e) {
      return Left(_mapError(e, 'Failed to rename PDF'));
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
  Future<Either<Failure, List<PdfEntity>>> sortPdfs(
    List<PdfEntity> pdfs,
    SortOption option,
  ) async {
    try {
      final sorted = List<PdfEntity>.from(pdfs);

      switch (option) {
        case SortOption.name:
          sorted.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
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
  Future<Either<Failure, PdfEntity>> savePdfBytes(
    Uint8List pdfBytes,
    String fileName, {
    String folderRelative = '',
  }) async {
    try {
      final filePath = await dataSource.savePdfBytes(
        pdfBytes,
        fileName,
        folderRelative: folderRelative,
      );
      final file = File(filePath);
      final modifiedTime = file.lastModifiedSync();
      final relative = folderRelative.isEmpty
          ? path.basename(filePath)
          : '$folderRelative/${path.basename(filePath)}';
      final pdfEntity = PdfEntity(
        file: file,
        name: path.basename(filePath),
        size: file.lengthSync(),
        createdAt: modifiedTime,
        modifiedAt: modifiedTime,
        relativePath: relative,
      );
      return Right(pdfEntity);
    } catch (e) {
      return Left(_mapError(e, 'Failed to save PDF'));
    }
  }

  @override
  Future<Either<Failure, PdfEntity>> mergePdfs(
    List<PdfEntity> pdfs,
    String outputName, {
    String folderRelative = '',
  }) async {
    try {
      await dataSource.mergePdfs(
        pdfs.map((p) => p.file.path).toList(),
        outputName,
        folderRelative: folderRelative,
      );
      final loaded = await loadPdfs();
      return loaded.fold(
        (failure) => Left(failure),
        (all) {
          final match = all.where(
            (pdf) =>
                pdf.name == outputName ||
                pdf.name.startsWith(
                  path.basenameWithoutExtension(outputName),
                ),
          );
          if (match.isEmpty) {
            return Left(PdfFailure('Merged PDF was not found after save'));
          }
          return Right(match.first);
        },
      );
    } catch (e) {
      return Left(_mapError(e, 'Failed to merge PDFs'));
    }
  }
}