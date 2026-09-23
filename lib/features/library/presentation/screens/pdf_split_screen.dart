import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';

enum SplitMode {
  selectedPages,
  allPages,
}

class PdfSplitScreen extends ConsumerStatefulWidget {
  final PdfEntity pdf;

  const PdfSplitScreen({super.key, required this.pdf});

  @override
  ConsumerState<PdfSplitScreen> createState() => _PdfSplitScreenState();
}

class _PdfSplitScreenState extends ConsumerState<PdfSplitScreen> {
  final Set<int> _selectedPages = {};
  List<pdfx.PdfPageImage> _pageImages = [];
  bool _isLoading = true;
  String? _errorMessage;
  SplitMode _splitMode = SplitMode.selectedPages;
  final TextEditingController _prefixController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPdfPages();
    _prefixController.text = widget.pdf.name.replaceAll('.pdf', '');
  }

  @override
  void dispose() {
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _loadPdfPages() async {
    try {
      final pdfBytes = await widget.pdf.file.readAsBytes();
      final pdfDoc = await pdfx.PdfDocument.openData(pdfBytes);
      final pageImages = <pdfx.PdfPageImage>[];

      for (var i = 1; i <= pdfDoc.pagesCount; i++) {
        final page = await pdfDoc.getPage(i);
        final pageImage = await page.render(
          width: page.width,
          height: page.height,
        );
        if (pageImage != null) {
          pageImages.add(pageImage);
        }
      }

      setState(() {
        _pageImages = pageImages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load PDF pages: $e';
      });
    }
  }

  void _togglePageSelection(int arrayIndex) {
    setState(() {
      final pageNumber = arrayIndex + 1;
      if (_selectedPages.contains(pageNumber)) {
        _selectedPages.remove(pageNumber);
      } else {
        _selectedPages.add(pageNumber);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPages.clear();
      for (var i = 0; i < _pageImages.length; i++) {
        _selectedPages.add(i + 1);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPages.clear();
    });
  }

  Future<void> _createSelectedPdfs() async {
    if (!_canSplit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one page')),
      );
      return;
    }

    try {
      final pdfBytes = await widget.pdf.file.readAsBytes();
      final pdfDoc = await pdfx.PdfDocument.openData(pdfBytes);
      
      final createdPdfs = <PdfEntity>[];
      final prefix = _prefixController.text.trim();
      
      if (_splitMode == SplitMode.selectedPages) {
        // Create ONE PDF with all selected pages
        final sortedPages = _selectedPages.toList()..sort();
        final mergedPdf = pw.Document();
        var pageCount = 0;
        
        for (final pageIndex in sortedPages) {
          try {
            final page = await pdfDoc.getPage(pageIndex);
            
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
            debugPrint('Error processing page $pageIndex: $pageError');
          }
        }
        
        if (pageCount > 0) {
          final outputName = '$prefix.pdf';
          final result = await ref.read(libraryProvider.notifier).savePdfBytes(
            await mergedPdf.save(),
            outputName,
          );
          
          result.fold(
            (failure) {
              debugPrint('Failed to save merged PDF: ${failure.message}');
            },
            (pdfEntity) {
              createdPdfs.add(pdfEntity);
            },
          );
        }
      } else {
        // Create individual PDFs for each page
        final pagesToSplit = List.generate(_pageImages.length, (index) => index + 1);
        
        for (final pageIndex in pagesToSplit) {
          try {
            final page = await pdfDoc.getPage(pageIndex);
            
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
              // Create a new PDF with this page
              final newPdf = pw.Document();
              final pdfImage = pw.MemoryImage(pageBytes);
              newPdf.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat(page.width.toDouble(), page.height.toDouble()),
                  build: (context) => pw.Image(pdfImage),
                ),
              );

              final outputName = '${prefix}_page_$pageIndex.pdf';
              
              // Save using the library facade
              final result = await ref.read(libraryProvider.notifier).savePdfBytes(
                await newPdf.save(),
                outputName,
              );
              
              result.fold(
                (failure) {
                  debugPrint('Failed to save page $pageIndex: ${failure.message}');
                },
                (pdfEntity) {
                  createdPdfs.add(pdfEntity);
                },
              );
            }
          } catch (pageError) {
            debugPrint('Error processing page $pageIndex: $pageError');
          }
        }
      }

      if (mounted) {
        if (createdPdfs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create any PDFs')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created ${createdPdfs.length} PDF${createdPdfs.length == 1 ? '' : 's'} from selected pages')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create PDFs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings placeholder
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => _loadPdfPages(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pageImages.isEmpty
                  ? Center(
                      child: Text(
                        'No pages found in PDF',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Preview Pages
                          _buildPreviewPages(theme, colorScheme),
                          
                          const SizedBox(height: 16),
                          
                          // Split Options
                          _buildSplitOptions(theme, colorScheme),
                          
                          const SizedBox(height: 16),
                          
                          // Output Settings
                          _buildOutputSettings(theme, colorScheme),
                          
                          const SizedBox(height: 16),
                          
                          // Action Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FilledButton.icon(
                              onPressed: _canSplit() ? _createSelectedPdfs : null,
                              icon: const Icon(Icons.content_cut),
                              label: Text(_splitMode == SplitMode.selectedPages 
                                  ? 'Merge Selected Pages (${_selectedPages.length})'
                                  : 'Split PDF (${_pageImages.length} Pages)'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                                disabledForegroundColor: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPreviewPages(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Preview Pages',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _pageImages.length,
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              return _PageThumbnail(
                pageImage: _pageImages[index],
                pageIndex: pageNumber,
                isSelected: _selectedPages.contains(pageNumber),
                onTap: () => _togglePageSelection(index),
                colorScheme: colorScheme,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSplitOptions(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Split Options',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              RadioListTile<SplitMode>(
                title: const Text('Merge selected pages into a new PDF'),
                subtitle: const Text('Create one PDF with selected pages'),
                value: SplitMode.selectedPages,
                groupValue: _splitMode,
                onChanged: (value) {
                  setState(() {
                    _splitMode = value!;
                  });
                },
              ),
              RadioListTile<SplitMode>(
                title: const Text('Split every page into a separate PDF'),
                subtitle: const Text('Create individual PDFs for each page'),
                value: SplitMode.allPages,
                groupValue: _splitMode,
                onChanged: (value) {
                  setState(() {
                    _splitMode = value!;
                    if (value == SplitMode.allPages) {
                      _selectAll();
                    }
                  });
                },
              ),
            ],
          ),
        ),
        if (_splitMode == SplitMode.selectedPages && _selectedPages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Selected pages: ${_selectedPages.toList()..sort()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text('Deselect All'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOutputSettings(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Output Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _prefixController,
            decoration: InputDecoration(
              labelText: 'File name',
              border: const OutlineInputBorder(),
              suffixText: _splitMode == SplitMode.selectedPages ? '.pdf' : '_page_1.pdf',
            ),
          ),
        ),
      ],
    );
  }

  bool _canSplit() {
    if (_splitMode == SplitMode.allPages) {
      return _pageImages.isNotEmpty;
    }
    return _selectedPages.isNotEmpty;
  }
}

class _PageThumbnail extends StatelessWidget {
  final pdfx.PdfPageImage pageImage;
  final int pageIndex;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _PageThumbnail({
    required this.pageImage,
    required this.pageIndex,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.memory(
                pageImage.bytes,
                fit: BoxFit.cover,
                width: 150,
                height: 200,
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: colorScheme.onPrimary, size: 20),
                ),
              ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Page $pageIndex',
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
