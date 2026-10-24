import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';

void main() {
  PdfEntity pdf(String relative, {int modified = 1}) {
    return PdfEntity(
      file: File(relative),
      name: relative.split('/').last,
      createdAt: DateTime.fromMillisecondsSinceEpoch(modified),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(modified),
      size: 10,
      relativePath: relative,
    );
  }

  test('All Documents shows every PDF; folders are scoped', () {
    final state = LibraryState(
      pdfs: [
        pdf('a.pdf', modified: 3),
        pdf('College/b.pdf', modified: 2),
        pdf('College/c.pdf', modified: 1),
      ],
    );
    expect(state.visiblePdfs, hasLength(3));
    expect(state.recentPdfs.first.name, 'a.pdf');

    final college = state.copyWith(currentFolderRelative: 'College');
    expect(college.visiblePdfs.map((p) => p.name), ['b.pdf', 'c.pdf']);
    expect(college.searchScopeLabel, 'Searching in College');
  });

  test('search can stay in the folder or cover the whole library', () {
    final state = LibraryState(
      pdfs: [
        pdf('a.pdf'),
        pdf('College/notes.pdf'),
      ],
      currentFolderRelative: 'College',
      searchQuery: 'a',
    );
    expect(state.visiblePdfs, isEmpty);

    final global = state.copyWith(searchAllDocuments: true);
    expect(global.visiblePdfs.map((p) => p.name), ['a.pdf']);
  });
}