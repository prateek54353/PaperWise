import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperwise_pdf_maker/features/library/data/services/library_file_system.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temp;
  late LibraryFileSystem fs;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('paperwise_library_');
    fs = LibraryFileSystem(Directory(p.join(temp.path, 'Paperwise', 'PDF')));
    await fs.ensureRoot();
  });

  tearDown(() async {
    if (await temp.exists()) {
      await temp.delete(recursive: true);
    }
  });

  Future<File> writePdf(String relative, {String contents = 'pdf'}) async {
    final file = fs.fileFor(relative);
    await file.parent.create(recursive: true);
    await file.writeAsString(contents);
    return file;
  }

  test('creates and lists folders with real document counts', () async {
    await fs.createFolder('', 'College');
    await writePdf('College/notes.pdf');
    await writePdf('root.pdf');

    final folders = await fs.listChildFolders('');
    expect(folders, hasLength(1));
    expect(p.basename(folders.first.path), 'College');
    expect(await fs.countPdfs('College'), 1);
    expect(await fs.countPdfs('', recursive: true), 2);
    expect(await fs.countPdfs('', recursive: false), 1);
  });

  test('rejects invalid and duplicate folder names', () async {
    await expectLater(
      fs.createFolder('', ''),
      throwsA(isA<FolderNameException>()),
    );
    await expectLater(
      fs.createFolder('', 'bad/name'),
      throwsA(isA<FolderNameException>()),
    );
    await fs.createFolder('', 'College');
    await expectLater(
      fs.createFolder('', 'College'),
      throwsA(isA<FolderNameException>()),
    );
  });

  test('renames a folder and keeps PDFs inside it', () async {
    await fs.createFolder('', 'College');
    await writePdf('College/notes.pdf');
    final renamed = await fs.renameFolder('College', 'University');
    expect(p.basename(renamed.path), 'University');
    expect(await fs.fileFor('University/notes.pdf').exists(), isTrue);
    expect(await fs.fileFor('College/notes.pdf').exists(), isFalse);
  });

  test('moves a PDF into a folder and back to the root', () async {
    await writePdf('invoice.pdf');
    await fs.createFolder('', 'Invoices');
    final moved = await fs.movePdf('invoice.pdf', 'Invoices');
    expect(fs.toRelative(moved.path), 'Invoices/invoice.pdf');
    expect(await fs.fileFor('invoice.pdf').exists(), isFalse);

    final restored = await fs.movePdf('Invoices/invoice.pdf', '');
    expect(fs.toRelative(restored.path), 'invoice.pdf');
  });

  test('moves multiple PDFs and nested folders', () async {
    await fs.createFolder('', 'College');
    await fs.createFolder('College', 'Lectures');
    await writePdf('a.pdf');
    await writePdf('b.pdf');
    await writePdf('College/Lectures/c.pdf');

    await fs.movePdfs(['a.pdf', 'b.pdf'], 'College');
    expect(await fs.countPdfs('College', recursive: false), 2);
    expect(await fs.countPdfs('College', recursive: true), 3);

    await fs.moveFolder('College/Lectures', '');
    expect(await fs.directoryFor('Lectures').exists(), isTrue);
    expect(await fs.fileFor('Lectures/c.pdf').exists(), isTrue);
  });

  test('duplicate destination names get a unique suffix', () async {
    await fs.createFolder('', 'A');
    await fs.createFolder('', 'B');
    await writePdf('A/file.pdf');
    await writePdf('B/file.pdf');
    final moved = await fs.movePdf('A/file.pdf', 'B');
    expect(p.basename(moved.path), 'file (1).pdf');
    expect(await fs.fileFor('B/file.pdf').exists(), isTrue);
  });

  test('deleting an empty folder succeeds and a filled folder requires recursive',
      () async {
    await fs.createFolder('', 'Empty');
    await fs.deleteFolder('Empty', recursive: false);
    expect(await fs.directoryFor('Empty').exists(), isFalse);

    await fs.createFolder('', 'Filled');
    await writePdf('Filled/keep.pdf');
    await expectLater(
      fs.deleteFolder('Filled', recursive: false),
      throwsA(isA<FolderNameException>()),
    );
    expect(await fs.fileFor('Filled/keep.pdf').exists(), isTrue);

    await fs.deleteFolder('Filled', recursive: true);
    expect(await fs.fileFor('Filled/keep.pdf').exists(), isFalse);
  });

  test('missing files are reported without deleting unrelated PDFs', () async {
    await writePdf('safe.pdf');
    await expectLater(
      fs.movePdf('missing.pdf', ''),
      throwsA(isA<LibraryIoException>()),
    );
    expect(await fs.fileFor('safe.pdf').exists(), isTrue);
  });

  test('relative paths stay inside the library root', () async {
    expect(
      () => fs.fileFor('../escape.pdf'),
      throwsA(isA<LibraryIoException>()),
    );
  });
}