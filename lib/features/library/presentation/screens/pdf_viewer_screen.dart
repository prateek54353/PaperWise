import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final PdfEntity pdf;

  const PdfViewerScreen({
    super.key,
    required this.pdf,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  late PdfController _pdfController;
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.pdf.file.path),
    );

    final document = await _pdfController.document;
    if (mounted) {
      setState(() {
        _totalPages = document.pagesCount;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _sharePdf() async {
    await ref.read(libraryProvider.notifier).sharePdf(widget.pdf);
  }

  Future<void> _downloadPdf() async {
    await ref.read(libraryProvider.notifier).downloadPdf(widget.pdf);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to Downloads'),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pdf.name,
              style: const TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!_isLoading)
              Text(
                'Page $_currentPage of $_totalPages',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _sharePdf,
            tooltip: 'Share PDF',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _downloadPdf,
            tooltip: 'Save to Downloads',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PdfView(
              controller: _pdfController,
              scrollDirection: Axis.vertical,
              pageSnapping: false,
              physics: const ClampingScrollPhysics(),
              onPageChanged: (page) {
                if (mounted) {
                  setState(() => _currentPage = page);
                }
              },
              builders: PdfViewBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(
                  loaderSwitchDuration: Duration(milliseconds: 200),
                ),
                documentLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                pageLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, error) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading PDF:\n${error.toString()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
