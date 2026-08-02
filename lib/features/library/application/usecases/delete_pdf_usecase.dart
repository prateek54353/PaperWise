import 'package:dartz/dartz.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import '../../domain/entities/pdf_entity.dart';
import '../../domain/repositories/pdf_repository.dart';

class DeletePdfUseCase {
  final PdfRepository repository;

  DeletePdfUseCase(this.repository);

  Future<Either<Failure, void>> call(PdfEntity pdf) async {
    return await repository.deletePdf(pdf);
  }

  Future<Either<Failure, void>> callMultiple(List<PdfEntity> pdfs) async {
    return await repository.deletePdfs(pdfs);
  }
}
