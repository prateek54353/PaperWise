import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';

class LibraryBreadcrumb extends ConsumerWidget {
  const LibraryBreadcrumb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crumbs = ref.watch(libraryProvider.select((state) => state.breadcrumbs));
    if (crumbs.length <= 1) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          for (var i = 0; i < crumbs.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(32, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: i == crumbs.length - 1
                  ? null
                  : () {
                      final relative = crumbs[i].relativePath;
                      if (relative == null) {
                        ref.read(libraryProvider.notifier).openAllDocuments();
                      } else {
                        ref.read(libraryProvider.notifier).openFolder(relative);
                      }
                    },
              child: Text(
                crumbs[i].label,
                style: TextStyle(
                  fontWeight:
                      i == crumbs.length - 1 ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
