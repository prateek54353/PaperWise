import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class PdfListItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // This widget is now compatible with both old and new usage patterns
    // It no longer depends on a specific state management approach
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () {
          // Long press is now handled by the parent component
        },
        child: Semantics(
          label: 'PDF file: ${path.basename(pdfFile.path)}',
          button: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 40,
                  color: colorScheme.primary,
                  semanticLabel: 'PDF icon',
                ),
                title: Text(
                  path.basename(pdfFile.path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  semanticsLabel: 'PDF file name: ${path.basename(pdfFile.path)}',
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
                trailing: PopupMenuButton<String>(
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
    );
  }
}