import 'package:dartz/dartz.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import '../../domain/entities/pdf_entity.dart';
import '../../domain/repositories/pdf_repository.dart';

class LoadPdfsUseCase {
  final PdfRepository repository;

  LoadPdfsUseCase(this.repository);

  Future<Either<Failure, List<PdfEntity>>> call() async {
    return await repository.loadPdfs();
  }
}
