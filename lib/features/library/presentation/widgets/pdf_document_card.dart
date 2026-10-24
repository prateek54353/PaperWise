import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/theme/app_tokens.dart';
import 'package:paperwise_pdf_maker/features/library/data/services/pdf_page_count_service.dart';
import 'package:paperwise_pdf_maker/features/library/data/services/pdf_thumbnail_service.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';

class PdfDocumentCard extends ConsumerStatefulWidget {
  const PdfDocumentCard({
    super.key,
    required this.pdf,
    required this.onOpen,
    required this.onRename,
    required this.onShare,
    required this.onDelete,
    this.onMove,
    this.onSplit,
    this.onCompress,
  });

  final PdfEntity pdf;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback? onMove;
  final VoidCallback? onSplit;
  final VoidCallback? onCompress;

  @override
  ConsumerState<PdfDocumentCard> createState() => _PdfDocumentCardState();
}

class _PdfDocumentCardState extends ConsumerState<PdfDocumentCard> {
  final PdfThumbnailService _thumbnailService = PdfThumbnailService();
  File? _thumbnailFile;
  int? _pageCount;
  bool _loadingThumb = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void didUpdateWidget(covariant PdfDocumentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdf.file.path != widget.pdf.file.path ||
        oldWidget.pdf.modifiedAt != widget.pdf.modifiedAt) {
      _loadMetadata();
    }
  }

  Future<void> _loadMetadata() async {
    setState(() => _loadingThumb = true);
    try {
      final thumbnail =
          await _thumbnailService.getThumbnailFile(widget.pdf.file);
      final pages =
          await PdfPageCountService.instance.getPageCount(widget.pdf.file);
      if (!mounted) return;
      setState(() {
        _thumbnailFile = thumbnail;
        _pageCount = pages;
        _loadingThumb = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingThumb = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(
      libraryProvider.select((state) => state.isPdfSelected(widget.pdf)),
    );
    final selectionMode = ref.watch(
      libraryProvider.select((state) => state.isSelectionMode),
    );
    final scheme = Theme.of(context).colorScheme;
    final pages = _pageCount ?? widget.pdf.pageCount;
    final pageLabel = pages <= 0
        ? _formatSize(widget.pdf.size)
        : (pages == 1 ? '1 Page' : '$pages Pages');

    return Semantics(
      label: 'PDF file: ${widget.pdf.name}',
      button: true,
      selected: selected,
      child: Material(
        color: scheme.surface,
        elevation: AppTokens.elevationCard,
        shadowColor: scheme.shadow.withValues(alpha: 0.06),
        borderRadius: AppTokens.borderRadiusMd,
        child: InkWell(
          borderRadius: AppTokens.borderRadiusMd,
          onTap: selectionMode
              ? () => ref
                  .read(libraryProvider.notifier)
                  .togglePdfSelection(widget.pdf)
              : widget.onOpen,
          onLongPress: () => ref
              .read(libraryProvider.notifier)
              .togglePdfSelection(widget.pdf),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTokens.radiusMd),
                      ),
                      child: ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: _loadingThumb
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _thumbnailFile != null
                                ? Image.file(
                                    _thumbnailFile!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _PdfFallbackIcon(color: scheme.primary),
                                  )
                                : _PdfFallbackIcon(color: scheme.primary),
                      ),
                    ),
                    if (selectionMode)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pdf.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$pageLabel · ${_formatSize(widget.pdf.size)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (!selectionMode)
                      PopupMenuButton<String>(
                        tooltip: 'Document actions',
                        onSelected: (value) {
                          switch (value) {
                            case 'open':
                              widget.onOpen();
                            case 'share':
                              widget.onShare();
                            case 'rename':
                              widget.onRename();
                            case 'move':
                              widget.onMove?.call();
                            case 'split':
                              widget.onSplit?.call();
                            case 'delete':
                              widget.onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'open',
                            child: ListTile(
                              leading: Icon(Icons.open_in_new),
                              title: Text('Open'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'share',
                            child: ListTile(
                              leading: Icon(Icons.share_outlined),
                              title: Text('Share'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'rename',
                            child: ListTile(
                              leading: Icon(Icons.drive_file_rename_outline),
                              title: Text('Rename'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          if (widget.onMove != null)
                            const PopupMenuItem(
                              value: 'move',
                              child: ListTile(
                                leading: Icon(Icons.drive_file_move_outline),
                                title: Text('Move to...'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          if (widget.onSplit != null)
                            const PopupMenuItem(
                              value: 'split',
                              child: ListTile(
                                leading: Icon(Icons.call_split),
                                title: Text('Split PDF'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: scheme.error,
                              ),
                              title: Text(
                                'Delete',
                                style: TextStyle(color: scheme.error),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfFallbackIcon extends StatelessWidget {
  const _PdfFallbackIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(Icons.picture_as_pdf_outlined, size: 40, color: color),
    );
  }
}