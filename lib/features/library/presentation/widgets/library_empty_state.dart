import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    super.key,
    required this.searching,
    required this.query,
    required this.inFolder,
    required this.onScan,
    required this.onCreateFolder,
  });

  final bool searching;
  final String query;
  final bool inFolder;
  final VoidCallback onScan;
  final VoidCallback onCreateFolder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searching ? Icons.search_off : Icons.folder_open_outlined,
            size: 72,
            color: scheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            searching
                ? 'No documents match “$query”'
                : inFolder
                    ? 'This folder is empty'
                    : 'No documents yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            searching
                ? 'Try a different name, or search all documents from Home.'
                : 'Scan a document or import images to get started.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          if (!searching) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onScan,
              child: const Text('Scan Document'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onCreateFolder,
              child: const Text('Create folder'),
            ),
          ],
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}
