import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/theme/app_tokens.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/folder_card.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/library_actions_mixin.dart';

class LibraryFolderStrip extends ConsumerWidget {
  const LibraryFolderStrip({super.key, required this.actions});

  final LibraryActionsMixin actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    final folders = [
      if (state.isAllDocuments || state.isLibraryRoot) state.allDocumentsFolder,
      ...state.folders,
    ];

    return SizedBox(
      height: AppTokens.folderCardHeight + 24,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: folders.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == folders.length) {
            return AddFolderCard(onTap: () => actions.createFolder());
          }
          final folder = folders[index];
          final selected = folder.isVirtualAll
              ? state.isAllDocuments
              : state.currentFolderRelative == folder.relativePath;
          return FolderCard(
            folder: folder,
            selected: selected,
            onTap: () {
              if (folder.isVirtualAll) {
                ref.read(libraryProvider.notifier).openAllDocuments();
              } else {
                ref.read(libraryProvider.notifier).openFolder(folder.relativePath);
              }
            },
            onMenuSelected: folder.isVirtualAll
                ? null
                : (value) => actions.handleFolderMenu(folder, value),
          );
        },
      ),
    );
  }
}
