import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/features/library/data/services/library_file_system.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/folder_entity.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';

Future<String?> showNameFieldSheet(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  String confirmLabel = 'Create',
  String? Function(String name)? validator,
}) {
  final controller = TextEditingController(text: initial);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _ValidatedNameSheet(
        title: title,
        label: label,
        controller: controller,
        confirmLabel: confirmLabel,
        validator: validator,
      );
    },
  );
}

class _ValidatedNameSheet extends StatefulWidget {
  const _ValidatedNameSheet({
    required this.title,
    required this.label,
    required this.controller,
    required this.confirmLabel,
    this.validator,
  });

  final String title;
  final String label;
  final TextEditingController controller;
  final String confirmLabel;
  final String? Function(String name)? validator;

  @override
  State<_ValidatedNameSheet> createState() => _ValidatedNameSheetState();
}

class _ValidatedNameSheetState extends State<_ValidatedNameSheet> {
  String? _error;

  void _submit() {
    final name = widget.controller.text.trim();
    final error = widget.validator?.call(name);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _submit,
                child: Text(widget.confirmLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreatedFolderRequest {
  const CreatedFolderRequest({required this.name, required this.parentRelative});
  final String name;
  final String parentRelative;
}

Future<CreatedFolderRequest?> showCreateFolderSheet(
  BuildContext context,
  WidgetRef ref, {
  String? initialParent,
}) async {
  final result = await ref.read(libraryFacadeProvider).getAllFolders();
  final folders = result.fold((_) => <FolderEntity>[], (value) => value);
  if (!context.mounted) return null;

  final current = initialParent ?? ref.read(libraryProvider).saveFolderRelative;
  var parent = current;
  final controller = TextEditingController();
  String? error;

  return showModalBottomSheet<CreatedFolderRequest>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final parentItems = <DropdownMenuItem<String>>[
            const DropdownMenuItem(
              value: '',
              child: Text('All Documents'),
            ),
            for (final folder in folders)
              DropdownMenuItem(
                value: folder.relativePath,
                child: Text(folder.relativePath.replaceAll('/', ' / ')),
              ),
          ];
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create folder',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Folder name',
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: parent,
                  decoration: const InputDecoration(labelText: 'Parent location'),
                  items: parentItems,
                  onChanged: (value) {
                    if (value != null) setState(() => parent = value);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        final name = controller.text.trim();
                        final validation =
                            LibraryFileSystem.validateFolderName(name);
                        if (validation != null) {
                          setState(() => error = validation);
                          return;
                        }
                        Navigator.pop(
                          context,
                          CreatedFolderRequest(
                            name: name,
                            parentRelative: parent,
                          ),
                        );
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Returns destination folder relative path. Empty string is library root.
Future<String?> showMoveDestinationSheet(
  BuildContext context,
  WidgetRef ref, {
  String? excludeFolderRelative,
  int itemCount = 1,
  String itemLabel = 'item',
}) async {
  final result = await ref.read(libraryFacadeProvider).getAllFolders();
  final folders = result.fold((_) => <FolderEntity>[], (value) => value).where((
    folder,
  ) {
    final excluded = excludeFolderRelative;
    if (excluded == null || excluded.isEmpty) return true;
    if (folder.relativePath == excluded) return false;
    return !folder.relativePath.startsWith('$excluded/');
  }).toList();

  if (!context.mounted) return null;

  final destination = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Text(
                'Move to folder',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_special_outlined),
              title: const Text('All Documents (library root)'),
              subtitle: const Text('Files stored at the top of the library'),
              onTap: () => Navigator.pop(context, ''),
            ),
            if (folders.isEmpty)
              const ListTile(
                title: Text('No folders yet'),
                subtitle: Text('Create a folder from the home screen first'),
              ),
            for (final folder in folders)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(folder.name),
                subtitle: Text(folder.relativePath.replaceAll('/', ' / ')),
                onTap: () => Navigator.pop(context, folder.relativePath),
              ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );

  if (destination == null || !context.mounted) return null;

  final destinationLabel =
      destination.isEmpty ? 'the library root' : destination.replaceAll('/', ' / ');
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm move'),
      content: Text(
        'Move $itemCount $itemLabel to $destinationLabel? The files stay in your PaperWise library.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Move'),
        ),
      ],
    ),
  );
  return confirmed == true ? destination : null;
}

Future<bool> confirmDeleteFolder(
  BuildContext context, {
  required FolderEntity folder,
}) async {
  final hasFiles = folder.documentCount > 0;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(hasFiles ? 'Delete folder and files?' : 'Delete folder?'),
        content: Text(
          hasFiles
              ? '“${folder.name}” contains ${folder.documentCount} '
                  '${folder.documentCount == 1 ? 'PDF' : 'PDFs'}. '
                  'This permanently deletes the folder and every PDF inside it. '
                  'This cannot be undone from the library.'
              : 'Delete the empty folder “${folder.name}”?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(hasFiles ? 'Delete folder and files' : 'Delete'),
          ),
        ],
      );
    },
  );
  return result == true;
}

Future<bool> confirmDeletePdf(BuildContext context, String name) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete PDF?'),
      content: Text(
        'Delete “$name”? You can undo this from the snackbar for a few seconds.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result == true;
}
