import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;
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
      if (allPdfs.isLeft()) {
        return allPdfs;
      }
      final pdfs = allPdfs.getOrElse(() => []);
      final filtered = pdfs.where((pdf) {
        return pdf.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
      return Right(filtered);
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
        case SortOption.size:
          sorted.sort((a, b) => b.size.compareTo(a.size));
          break;
        case SortOption.pageCount:
          sorted.sort((a, b) => b.pageCount.compareTo(a.pageCount));
          break;
      }

      return Right(sorted);
    } catch (e) {
      return Left(PdfFailure('Failed to sort PDFs: $e'));
    }
  }

  @override
  Future<Either<Failure, PdfEntity>> mergePdfs(List<PdfEntity> pdfs, String outputName) async {
    try {
      if (pdfs.isEmpty) {
        return const Left(PdfFailure('No PDFs selected for merging'));
      }

      final mergedPdf = pw.Document();
      var pageCount = 0;

      for (final pdf in pdfs) {
        try {
          final pdfBytes = await pdf.file.readAsBytes();
          final sourcePdf = await pdfx.PdfDocument.openData(pdfBytes);
          
          for (var i = 1; i <= sourcePdf.pagesCount; i++) {
            try {
              final page = await sourcePdf.getPage(i);
              
              // Try rendering with different resolutions
              List<int> resolutions = [2, 1, 3];
              Uint8List? pageBytes;
              
              for (final resolution in resolutions) {
                try {
                  final pageImage = await page.render(
                    width: page.width * resolution,
                    height: page.height * resolution,
                  );
                  pageBytes = pageImage?.bytes;
                  if (pageBytes != null && pageBytes.isNotEmpty) {
                    break;
                  }
                } catch (renderError) {
                  continue;
                }
              }
              
              if (pageBytes != null && pageBytes.isNotEmpty) {
                final pdfImage = pw.MemoryImage(pageBytes);
                mergedPdf.addPage(
                  pw.Page(
                    pageFormat: PdfPageFormat(page.width.toDouble(), page.height.toDouble()),
                    build: (context) => pw.Image(pdfImage),
                  ),
                );
                pageCount++;
              }
            } catch (pageError) {
              debugPrint('Error processing page $i from ${pdf.name}: $pageError');
              continue;
            }
          }
        } catch (pdfError) {
          debugPrint('Error processing PDF ${pdf.name}: $pdfError');
          continue;
        }
      }

      if (pageCount == 0) {
        return const Left(PdfFailure('No pages could be merged from the selected PDFs'));
      }

      final outputPath = await dataSource.savePdfBytes(
        await mergedPdf.save(),
        outputName,
      );

      final stat = await File(outputPath).stat();
      final mergedPdfEntity = PdfEntity(
        file: File(outputPath),
        name: outputName,
        createdAt: stat.modified,
        modifiedAt: stat.modified,
        size: stat.size,
        pageCount: pageCount,
      );

      return Right(mergedPdfEntity);
    } catch (e) {
      return Left(PdfFailure('Failed to merge PDFs: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PdfEntity>>> splitPdf(PdfEntity pdf) async {
    try {
      final pdfBytes = await pdf.file.readAsBytes();
      final sourcePdf = await pdfx.PdfDocument.openData(pdfBytes);
      final splitPdfs = <PdfEntity>[];

      for (var i = 1; i <= sourcePdf.pagesCount; i++) {
        try {
          final page = await sourcePdf.getPage(i);
          
          // Try rendering with different resolutions
          List<int> resolutions = [2, 1, 3]; // Try 2x, 1x, 3x resolution
          Uint8List? pageBytes;
          
          for (final resolution in resolutions) {
            try {
              final pageImage = await page.render(
                width: page.width * resolution,
                height: page.height * resolution,
              );
              pageBytes = pageImage?.bytes;
              if (pageBytes != null && pageBytes.isNotEmpty) {
                break; // Use this resolution if successful
              }
            } catch (renderError) {
              // Try next resolution
              continue;
            }
          }
          
          if (pageBytes != null && pageBytes.isNotEmpty) {
            final singlePagePdf = pw.Document();
            final pdfImage = pw.MemoryImage(pageBytes);
            singlePagePdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat(page.width.toDouble(), page.height.toDouble()),
                build: (context) => pw.Image(pdfImage),
              ),
            );

            final baseName = pdf.name.replaceAll('.pdf', '');
            final outputName = '${baseName}_page_$i.pdf';
            
            final outputPath = await dataSource.savePdfBytes(
              await singlePagePdf.save(),
              outputName,
            );

            final stat = await File(outputPath).stat();
            splitPdfs.add(PdfEntity(
              file: File(outputPath),
              name: outputName,
              createdAt: stat.modified,
              modifiedAt: stat.modified,
              size: stat.size,
              pageCount: 1,
            ));
          } else {
            // If rendering completely failed, create a placeholder PDF
            final singlePagePdf = pw.Document();
            singlePagePdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                build: (context) => pw.Center(
                  child: pw.Text('Page $i - Rendering failed'),
                ),
              ),
            );

            final baseName = pdf.name.replaceAll('.pdf', '');
            final outputName = '${baseName}_page_${i}_error.pdf';
            
            final outputPath = await dataSource.savePdfBytes(
              await singlePagePdf.save(),
              outputName,
            );

            final stat = await File(outputPath).stat();
            splitPdfs.add(PdfEntity(
              file: File(outputPath),
              name: outputName,
              createdAt: stat.modified,
              modifiedAt: stat.modified,
              size: stat.size,
              pageCount: 1,
            ));
          }
        } catch (pageError) {
          debugPrint('Error processing page $i: $pageError');
          // Continue with next page
        }
      }

      if (splitPdfs.isEmpty) {
        return const Left(PdfFailure('No pages could be split from the PDF'));
      }

      return Right(splitPdfs);
    } catch (e) {
      return Left(PdfFailure('Failed to split PDF: $e'));
    }
  }

  @override
  Future<Either<Failure, PdfEntity>> savePdfBytes(List<int> bytes, String name) async {
    try {
      final outputPath = await dataSource.savePdfBytes(bytes, name);
      final stat = await File(outputPath).stat();
      final pdfEntity = PdfEntity(
        file: File(outputPath),
        name: name,
        createdAt: stat.modified,
        modifiedAt: stat.modified,
        size: stat.size,
        pageCount: 1, // Default to 1, will be updated when loaded
      );
      return Right(pdfEntity);
    } catch (e) {
      return Left(PdfFailure('Failed to save PDF: $e'));
    }
  }
}
