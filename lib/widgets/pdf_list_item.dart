import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:paperwise_pdf_maker/providers/pdf_provider.dart';
import 'package:path/path.dart' as path;

class PdfListItem extends StatelessWidget {
  final File pdfFile;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onCrop;
  final VoidCallback onRename;
  final VoidCallback onShare;

  const PdfListItem({
    super.key,
    required this.pdfFile,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    required this.onCrop,
    required this.onRename,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final pdfProvider = context.watch<PdfProvider>();
    final isSelected = pdfProvider.isPdfSelected(pdfFile);
    final isSelectionMode = pdfProvider.isSelectionMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSelectionMode ? () => pdfProvider.togglePdfSelection(pdfFile) : onTap,
        onLongPress: () {
          if (!isSelectionMode) {
            pdfProvider.togglePdfSelection(pdfFile);
          }
        },
        child: Container(
          color: isSelected ? colorScheme.primaryContainer.withOpacity(0.2) : null,
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
                    ),
                    if (isSelectionMode)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer.withOpacity(0.8)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                )
                              : const Icon(Icons.circle_outlined),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  path.basename(pdfFile.path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM d, y • h:mm a').format(pdfFile.lastModifiedSync()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    FutureBuilder<int>(
                      future: pdfFile.length(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final sizeInKB = snapshot.data! / 1024;
                        final sizeText = sizeInKB > 1024
                            ? '${(sizeInKB / 1024).toStringAsFixed(1)} MB'
                            : '${sizeInKB.toStringAsFixed(1)} KB';
                        return Text(
                          sizeText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.secondary,
                          ),
                        );
                      },
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
                                Icon(Icons.drive_file_rename_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text('Rename', style: TextStyle(color: Colors.blue.shade700)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share_outlined, color: Colors.green.shade700),
                                const SizedBox(width: 8),
                                Text('Share', style: TextStyle(color: Colors.green.shade700)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red.shade700)),
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
    );
  }
}