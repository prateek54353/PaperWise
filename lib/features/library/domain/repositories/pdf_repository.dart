import 'package:dartz/dartz.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import '../entities/pdf_entity.dart';

enum SortOption { date, name }

abstract class PdfRepository {
  Future<Either<Failure, List<PdfEntity>>> loadPdfs();
  Future<Either<Failure, void>> deletePdf(PdfEntity pdf);
  Future<Either<Failure, void>> deletePdfs(List<PdfEntity> pdfs);
  Future<Either<Failure, void>> sharePdf(PdfEntity pdf);
  Future<Either<Failure, PdfEntity>> downloadPdf(PdfEntity pdf);
  Future<Either<Failure, PdfEntity>> renamePdf(PdfEntity pdf, String newName);
  Future<Either<Failure, List<PdfEntity>>> searchPdfs(String query);
  Future<Either<Failure, List<PdfEntity>>> sortPdfs(List<PdfEntity> pdfs, SortOption option);
}
