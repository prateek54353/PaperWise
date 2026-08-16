import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperwise_pdf_maker/services/pdf_service.dart';

void main() {
  group('PDFService cleanup', () {
    test('clears all generated temp files from a directory', () async {
      final root = await Directory.systemTemp.createTemp('pdf_service_test_');
      final nestedDir = Directory('${root.path}/nested');
      await nestedDir.create(recursive: true);

      final tempFile = File('${nestedDir.path}/scan_123.jpg');
      await tempFile.writeAsString('temp image data');

      await PDFService.clearDirectory(root);

      expect(await tempFile.exists(), isFalse);
      expect(await root.list().isEmpty, isTrue);
    });
  });
}
