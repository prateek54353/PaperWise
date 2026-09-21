import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';

class PdfMergeScreen extends ConsumerStatefulWidget {
  final List<PdfEntity> pdfs;

  const PdfMergeScreen({super.key, required this.pdfs});

  @override
  ConsumerState<PdfMergeScreen> createState() => _PdfMergeScreenState();
}

class _PdfMergeScreenState extends ConsumerState<PdfMergeScreen> {
  late List<PdfEntity> _orderedPdfs;
  bool _isMerging = false;
  double _mergeProgress = 0.0;
  final Map<String, Uint8List> _pdfPreviews = {};
  bool _isLoadingPreviews = true;

  @override
  void initState() {
    super.initState();
    _orderedPdfs = List.from(widget.pdfs);
    _loadPdfPreviews();
  }

  Future<void> _loadPdfPreviews() async {
    setState(() {
      _isLoadingPreviews = true;
    });

    for (final pdf in _orderedPdfs) {
      try {
        final pdfBytes = await pdf.file.readAsBytes();
        final pdfDoc = await pdfx.PdfDocument.openData(pdfBytes);
        
        if (pdfDoc.pagesCount > 0) {
          final page = await pdfDoc.getPage(1);
          final pageImage = await page.render(
            width: 300,
            height: 400,
          );
          
          if (pageImage?.bytes != null) {
            _pdfPreviews[pdf.file.path] = pageImage!.bytes;
          }
        }
        
        await pdfDoc.close();
      } catch (e) {
        debugPrint('Failed to load preview for ${pdf.name}: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingPreviews = false;
      });
    }
  }

  Future<void> _mergePdfs() async {
    final controller = TextEditingController(text: 'merged_document');
    
    final outputName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge PDFs'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Output PDF Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, '$name.pdf');
              }
            },
            child: const Text('Merge'),
          ),
        ],
      ),
    );

    if (outputName != null && mounted) {
      setState(() {
        _isMerging = true;
        _mergeProgress = 0.0;
      });

      // Simulate progress updates during merge
      final totalPdfs = _orderedPdfs.length;
      for (int i = 0; i < totalPdfs; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _mergeProgress = ((i + 1) / totalPdfs * 100).clamp(0.0, 100.0);
          });
        }
      }

      final result = await ref.read(libraryProvider.notifier).mergePdfs(_orderedPdfs, outputName);
      
      if (mounted) {
        setState(() {
          _isMerging = false;
          _mergeProgress = 0.0;
        });

        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Merge failed: ${failure.message}')),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDFs merged successfully')),
            );
            Navigator.pop(context);
          },
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _reorderPdfs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _orderedPdfs.removeAt(oldIndex);
      _orderedPdfs.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge PDFs'),
        actions: [
          if (_orderedPdfs.length > 1)
            IconButton(
              icon: const Icon(Icons.sort_by_alpha),
              onPressed: () {
                setState(() {
                  _orderedPdfs.sort((a, b) => a.name.compareTo(b.name));
                });
              },
              tooltip: 'Sort by name',
            ),
        ],
      ),
      body: _isMerging
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Merging PDFs... ${_mergeProgress.toInt()}%',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: _mergeProgress / 100,
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            )
          : _isLoadingPreviews
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Loading PDF previews...',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
          : _orderedPdfs.isEmpty
              ? Center(
                  child: Text(
                    'No PDFs selected',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orderedPdfs.length,
                        onReorder: _reorderPdfs,
                        itemBuilder: (context, index) {
                          final pdf = _orderedPdfs[index];
                          return _buildPdfItem(pdf, index, theme, colorScheme);
                        },
                      ),
                    ),
                    _buildMergeButton(theme, colorScheme),
                  ],
                ),
    );
  }

  Widget _buildPdfItem(PdfEntity pdf, int index, ThemeData theme, ColorScheme colorScheme) {
    final previewBytes = _pdfPreviews[pdf.file.path];
    
    return Card(
      key: ValueKey(pdf.file.path),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // PDF Preview Thumbnail
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: previewBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.memory(
                        previewBytes,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 100,
                      ),
                    )
                  : Icon(
                      Icons.picture_as_pdf,
                      color: colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
            ),
            const SizedBox(width: 16),
            // PDF Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pdf.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pdf.pageCount} pages • ${_formatFileSize(pdf.size)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _showPdfOptions(pdf, index, theme, colorScheme);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfOptions(PdfEntity pdf, int index, ThemeData theme, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.move_up, color: colorScheme.onSurfaceVariant),
              title: Text(
                'Move Up',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                if (index > 0) {
                  _reorderPdfs(index, index - 1);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.move_down, color: colorScheme.onSurfaceVariant),
              title: Text(
                'Move Down',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                if (index < _orderedPdfs.length - 1) {
                  _reorderPdfs(index, index + 1);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: colorScheme.error),
              title: Text(
                'Remove from merge',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _orderedPdfs.removeAt(index);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMergeButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: _orderedPdfs.length >= 2 ? _mergePdfs : null,
          icon: const Icon(Icons.merge),
          label: Text('Merge PDFs (${_orderedPdfs.length} Files)'),
          style: FilledButton.styleFrom(
            disabledBackgroundColor: colorScheme.surfaceContainerHighest,
            disabledForegroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
