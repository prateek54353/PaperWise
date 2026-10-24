import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/core/theme/app_tokens.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/folder_entity.dart';

class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.folder,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.onMenuSelected,
  });

  final FolderEntity folder;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<String>? onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = folder.documentCount;
    final countLabel = count == 1 ? '1 File' : '$count Files';

    return SizedBox(
      width: AppTokens.folderCardWidth,
      height: AppTokens.folderCardHeight,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerLowest,
        borderRadius: AppTokens.borderRadiusMd,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: AppTokens.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      folder.isVirtualAll
                          ? Icons.folder_special_rounded
                          : Icons.folder_rounded,
                      color: selected
                          ? scheme.onPrimary
                          : scheme.primary,
                    ),
                    const Spacer(),
                    if (!folder.isVirtualAll && onMenuSelected != null)
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: PopupMenuButton<String>(
                          tooltip: 'Folder actions',
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: selected
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                          onSelected: onMenuSelected,
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'open',
                              child: Text('Open'),
                            ),
                            PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            PopupMenuItem(
                              value: 'subfolder',
                              child: Text('Add subfolder'),
                            ),
                            PopupMenuItem(
                              value: 'move',
                              child: Text('Move to...'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: selected
                            ? scheme.onPrimary
                            : scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  countLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected
                            ? scheme.onPrimary.withValues(alpha: 0.85)
                            : scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddFolderCard extends StatelessWidget {
  const AddFolderCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppTokens.folderCardWidth,
      height: AppTokens.folderCardHeight,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusMd,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTokens.borderRadiusMd,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.create_new_folder_outlined, color: scheme.primary),
              const SizedBox(height: AppTokens.space8),
              Text(
                'Add Folder',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}