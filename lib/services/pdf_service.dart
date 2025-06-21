import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pwf;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'package:open_filex/open_filex.dart';
import 'package:paperwise_pdf_maker/screens/scan_screen.dart';

class PDFService {
  Future<File> createPDF(List<File> images, String customName, PageSizeMode pageSizeMode) async {
    final pdf = pw.Document();

    final Map<PageSizeMode, pwf.PdfPageFormat> formatMap = {
      PageSizeMode.a4: pwf.PdfPageFormat.a4,
      PageSizeMode.letter: pwf.PdfPageFormat.letter,
      PageSizeMode.legal: pwf.PdfPageFormat.legal,
    };

    for (var imageFile in images) {
      final image = pw.MemoryImage(await imageFile.readAsBytes());
      
      pwf.PdfPageFormat pageFormat;

      if (pageSizeMode == PageSizeMode.fit) {
        pageFormat = pwf.PdfPageFormat(
          image.width!.toDouble(), 
          image.height!.toDouble(),
          marginAll: 0,
        );
      } else {
        pageFormat = formatMap[pageSizeMode] ?? pwf.PdfPageFormat.a4;
      }

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final output = await getApplicationDocumentsDirectory();
    final fileName = '${customName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.pdf';
    final file = File(path.join(output.path, fileName));

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> openPdfExternal(File pdfFile) async {
    await OpenFilex.open(pdfFile.path);
  }

  Future<void> sharePDF(File pdfFile) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      text: 'Check out this PDF I created with Paperwise!',
    );
  }
}