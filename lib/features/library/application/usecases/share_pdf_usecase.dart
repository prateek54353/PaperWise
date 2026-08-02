import 'package:dartz/dartz.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import '../../domain/entities/pdf_entity.dart';
import '../../domain/repositories/pdf_repository.dart';

class SharePdfUseCase {
  final PdfRepository repository;

  SharePdfUseCase(this.repository);

  Future<Either<Failure, void>> call(PdfEntity pdf) async {
    return await repository.sharePdf(pdf);
  }
}
