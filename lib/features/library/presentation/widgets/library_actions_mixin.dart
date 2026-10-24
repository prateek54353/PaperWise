import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/utils/error_handler.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/folder_entity.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/pdf_merge_screen.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/pdf_split_screen.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/pdf_viewer_screen.dart';
import 'package:paperwise_pdf_maker/features/library/data/services/library_file_system.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/library_dialogs.dart';
import 'package:paperwise_pdf_maker/features/scan/presentation/screens/scan_screen.dart';
import 'package:path/path.dart' as path;

mixin LibraryActionsMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Future<void> navigateToScan() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (created == true && mounted) {
      await ref.read(libraryProvider.notifier).loadPdfs();
    }
  }

  void openPdf(PdfEntity pdf) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PdfViewerScreen(pdf: pdf)),
    );
  }

  void splitPdf(PdfEntity pdf) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PdfSplitScreen(pdf: pdf)),
    );
  }

  void mergeSelected() {
    final selected = ref.read(libraryProvider).selectedPdfs;
    if (selected.length < 2) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PdfMergeScreen(pdfs: selected)),
    );
  }

  Future<void> renamePdf(PdfEntity pdf) async {
    final name = await showNameFieldSheet(
      context,
      title: 'Rename PDF',
      label: 'File name',
      initial: path.basenameWithoutExtension(pdf.name),
      confirmLabel: 'Rename',
    );
    if (name == null || !mounted) return;
    await ref.read(libraryProvider.notifier).renamePdf(pdf, '$name.pdf');
    if (mounted) ErrorHandler.showSuccess(context, 'PDF renamed');
  }

  Future<void> deletePdf(PdfEntity pdf) async {
    final confirmed = await confirmDeletePdf(context, pdf.name);
    if (!confirmed || !mounted) return;
    await ref.read(libraryProvider.notifier).deletePdf(pdf);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('“${pdf.name}” deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await ref.read(libraryProvider.notifier).undoDeletePdf(pdf);
          },
        ),
      ),
    );
  }

  Future<void> sharePdf(PdfEntity pdf) async {
    await ref.read(libraryProvider.notifier).sharePdf(pdf);
  }

  Future<void> movePdf(PdfEntity pdf) async {
    final destination = await showMoveDestinationSheet(
      context,
      ref,
      itemCount: 1,
      itemLabel: 'PDF',
    );
    if (destination == null || !mounted) return;
    final result = await ref
        .read(libraryProvider.notifier)
        .movePdfsToFolder([pdf], destination);
    if (!mounted) return;
    result.fold(
      (failure) => ErrorHandler.showError(context, failure),
      (_) => ErrorHandler.showSuccess(context, 'Moved ${pdf.name}'),
    );
  }

  Future<void> moveSelected() async {
    final selected = ref.read(libraryProvider).selectedPdfs;
    if (selected.isEmpty) return;
    final destination = await showMoveDestinationSheet(
      context,
      ref,
      itemCount: selected.length,
      itemLabel: selected.length == 1 ? 'PDF' : 'PDFs',
    );
    if (destination == null || !mounted) return;
    final result = await ref
        .read(libraryProvider.notifier)
        .movePdfsToFolder(selected, destination);
    if (!mounted) return;
    result.fold(
      (failure) => ErrorHandler.showError(context, failure),
      (_) => ErrorHandler.showSuccess(
        context,
        'Moved ${selected.length} ${selected.length == 1 ? 'PDF' : 'PDFs'}',
      ),
    );
  }

  Future<void> createFolder({String? parent}) async {
    if (parent != null) {
      final name = await showNameFieldSheet(
        context,
        title: 'Create subfolder',
        label: 'Folder name',
        validator: LibraryFileSystem.validateFolderName,
      );
      if (name == null || !mounted) return;
      final result =
          await ref.read(libraryProvider.notifier).createSubfolder(parent, name);
      if (!mounted) return;
      result.fold(
        (failure) => ErrorHandler.showError(context, failure),
        (_) => ErrorHandler.showSuccess(context, 'Folder created'),
      );
      return;
    }

    final request = await showCreateFolderSheet(context, ref);
    if (request == null || !mounted) return;
    final result = await ref.read(libraryProvider.notifier).createFolder(
          request.name,
          parentRelative: request.parentRelative,
        );
    if (!mounted) return;
    result.fold(
      (failure) => ErrorHandler.showError(context, failure),
      (_) => ErrorHandler.showSuccess(context, 'Folder created'),
    );
  }

  Future<void> renameFolder(FolderEntity folder) async {
    final name = await showNameFieldSheet(
      context,
      title: 'Rename folder',
      label: 'Folder name',
      initial: folder.name,
      confirmLabel: 'Rename',
      validator: LibraryFileSystem.validateFolderName,
    );
    if (name == null || !mounted) return;
    final result =
        await ref.read(libraryProvider.notifier).renameFolder(folder, name);
    if (!mounted) return;
    result.fold(
      (failure) => ErrorHandler.showError(context, failure),
      (_) => ErrorHandler.showSuccess(context, 'Folder renamed'),
    );
  }

  Future<void> deleteFolder(FolderEntity folder) async {
    final confirmed = await confirmDeleteFolder(context, folder: folder);
    if (!confirmed || !mounted) return;
    final result = await ref.read(libraryProvider.notifier).deleteFolder(
          folder,
          recursive: folder.documentCount > 0,
        );
    if (!mounted) return;
    result.fold(
      (failure) => ErrorHandler.showError(context, failure),
      (_) => ErrorHandler.showSuccess(context, 'Folder deleted'),
    );
  }

  Future<void> moveFolder(FolderEntity folder) async {
    final destination = await showMoveDestinationSheet(
      context,
      ref,
      excludeFolderRelative: folder.relativePath,
      itemCount: 1,
      itemLabel: 'folder',
    );
    if (destination == null || !mounted) return;
    final result =
        await ref.read(libraryProvider.notifier).moveFolder(folder, destination);
    if (!mounted) return;
    result.fold(
      (failure) => ErrorHandler.showError(context, failure),
      (_) => ErrorHandler.showSuccess(context, 'Folder moved'),
    );
  }

  Future<void> handleFolderMenu(FolderEntity folder, String action) async {
    switch (action) {
      case 'open':
        await ref.read(libraryProvider.notifier).openFolder(folder.relativePath);
      case 'rename':
        await renameFolder(folder);
      case 'subfolder':
        await createFolder(parent: folder.relativePath);
      case 'move':
        await moveFolder(folder);
      case 'delete':
        await deleteFolder(folder);
    }
  }
}