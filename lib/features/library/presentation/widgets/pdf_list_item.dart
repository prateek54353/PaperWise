import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';

class PdfListItem extends ConsumerWidget {
  final PdfEntity pdf;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const PdfListItem({
    super.key,
    required this.pdf,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final isSelected = libraryState.isPdfSelected(pdf);
    final isSelectionMode = libraryState.isSelectionMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSelectionMode
            ? () => ref.read(libraryProvider.notifier).togglePdfSelection(pdf)
            : onTap,
        onLongPress: () {
          if (!isSelectionMode) {
            ref.read(libraryProvider.notifier).togglePdfSelection(pdf);
          }
        },
        child: Semantics(
          label: 'PDF file: ${pdf.name}',
          selected: isSelected,
          button: true,
          child: Container(
            color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.2) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 40,
                        color: colorScheme.primary,
                        semanticLabel: 'PDF icon',
                      ),
                      if (isSelectionMode)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer.withValues(alpha: 0.8)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: colorScheme.primary,
                                    semanticLabel: 'Selected',
                                  )
                                : const Icon(Icons.circle_outlined, semanticLabel: 'Not selected'),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    pdf.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    semanticsLabel: 'PDF file name: ${pdf.name}',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM d, y • h:mm a').format(pdf.modifiedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _formatFileSize(pdf.size),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  trailing: isSelectionMode
                      ? null
                      : PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.drive_file_rename_outline, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text('Rename', style: TextStyle(color: colorScheme.primary)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share_outlined, color: colorScheme.secondary),
                                  const SizedBox(width: 8),
                                  Text('Share', style: TextStyle(color: colorScheme.secondary)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: colorScheme.error),
                                  const SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: colorScheme.error)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'rename':
                                onRename();
                                break;
                              case 'share':
                                onShare();
                                break;
                              case 'delete':
                                onDelete();
                                break;
                            }
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
