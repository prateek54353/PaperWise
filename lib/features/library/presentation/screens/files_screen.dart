import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/library_actions_mixin.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/library_breadcrumb.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/library_empty_state.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/library_folder_strip.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/pdf_document_card.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/pdf_list_item.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen>
    with LibraryActionsMixin {
  bool _grid = true;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _gridCount(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);
    final pdfs = state.visiblePdfs;
    final selectionMode = state.isSelectionMode;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: !state.isAllDocuments
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    ref.read(libraryProvider.notifier).navigateUp(),
              )
            : null,
        title: selectionMode
            ? Text('${state.selectedCount} selected')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Files'),
                  Text(
                    state.isAllDocuments
                        ? 'All indexed documents'
                        : state.currentFolderName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
        actions: selectionMode
            ? [
                if (state.selectedCount >= 2)
                  IconButton(
                    icon: const Icon(Icons.merge_type),
                    tooltip: 'Merge selected',
                    onPressed: mergeSelected,
                  ),
                IconButton(
                  icon: const Icon(Icons.drive_file_move_outline),
                  tooltip: 'Move selected',
                  onPressed: moveSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share selected',
                  onPressed: () =>
                      ref.read(libraryProvider.notifier).shareSelectedPdfs(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete selected',
                  onPressed: () async {
                    await ref.read(libraryProvider.notifier).deleteSelectedPdfs();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear selection',
                  onPressed: () =>
                      ref.read(libraryProvider.notifier).clearSelection(),
                ),
              ]
            : [
                IconButton(
                  tooltip: _grid ? 'List view' : 'Grid view',
                  icon: Icon(_grid ? Icons.view_list_outlined : Icons.grid_view),
                  onPressed: () => setState(() => _grid = !_grid),
                ),
                IconButton(
                  tooltip: 'Select',
                  icon: const Icon(Icons.checklist),
                  onPressed: () =>
                      ref.read(libraryProvider.notifier).toggleSelectionMode(),
                ),
              ],
      ),
      body: Column(
        children: [
          const LibraryBreadcrumb(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: state.searchScopeLabel,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(libraryProvider.notifier).setSearchQuery('');
                        },
                      ),
              ),
              onChanged: (value) =>
                  ref.read(libraryProvider.notifier).setSearchQuery(value),
            ),
          ),
          if (!state.isAllDocuments)
            SwitchListTile(
              title: const Text('Search all documents'),
              subtitle: const Text('Include PDFs outside this folder'),
              value: state.searchAllDocuments,
              onChanged: (value) => ref
                  .read(libraryProvider.notifier)
                  .setSearchAllDocuments(value),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(libraryProvider.notifier).loadPdfs(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: LibraryFolderStrip(actions: this),
                      ),
                      if (pdfs.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: LibraryEmptyState(
                            searching: state.searchQuery.isNotEmpty,
                            query: state.searchQuery,
                            inFolder: !state.isAllDocuments,
                            onScan: navigateToScan,
                            onCreateFolder: createFolder,
                          ),
                        )
                      else if (_grid)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _gridCount(constraints.maxWidth),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final pdf = pdfs[index];
                                return PdfDocumentCard(
                                  key: ValueKey(pdf.relativePath),
                                  pdf: pdf,
                                  onOpen: () => openPdf(pdf),
                                  onRename: () => renamePdf(pdf),
                                  onShare: () => sharePdf(pdf),
                                  onDelete: () => deletePdf(pdf),
                                  onMove: () => movePdf(pdf),
                                  onSplit: () => splitPdf(pdf),
                                );
                              },
                              childCount: pdfs.length,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final pdf = pdfs[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: PdfListItem(
                                    pdf: pdf,
                                    onTap: () => openPdf(pdf),
                                    onRename: () => renamePdf(pdf),
                                    onShare: () => sharePdf(pdf),
                                    onDelete: () => deletePdf(pdf),
                                    onMove: () => movePdf(pdf),
                                    onSplit: () => splitPdf(pdf),
                                  ),
                                );
                              },
                              childCount: pdfs.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
