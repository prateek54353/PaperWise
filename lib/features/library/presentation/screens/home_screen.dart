import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/utils/error_handler.dart';
import 'package:paperwise_pdf_maker/features/library/domain/repositories/pdf_repository.dart'
    show SortOption;
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/library_actions_mixin.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/library_breadcrumb.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/library_empty_state.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/library_folder_strip.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/paperwise_brand.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/pdf_document_card.dart';
import 'package:paperwise_pdf_maker/features/settings/presentation/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with LibraryActionsMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _viewAllInFolder = false;

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
    final libraryState = ref.watch(libraryProvider);
    final isSelectionMode = libraryState.isSelectionMode;

    if (libraryState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ErrorHandler.showError(context, libraryState.error!);
        ref.read(libraryProvider.notifier).clearError();
      });
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: !libraryState.isAllDocuments
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    ref.read(libraryProvider.notifier).navigateUp(),
              )
            : null,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: libraryState.searchScopeLabel,
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) {
                  ref.read(libraryProvider.notifier).setSearchQuery(value);
                },
              )
            : isSelectionMode
                ? Text('${libraryState.selectedCount} selected')
                : libraryState.isAllDocuments
                    ? const PaperWiseAppBarTitle()
                    : Text(libraryState.currentFolderName),
        actions: isSelectionMode
            ? [
                if (libraryState.selectedCount >= 2)
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
                if (!_isSearching)
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Search',
                    onPressed: () => setState(() => _isSearching = true),
                  ),
                if (!_isSearching)
                  PopupMenuButton<SortOption>(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sort',
                    onSelected: (option) =>
                        ref.read(libraryProvider.notifier).setSortOption(option),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: SortOption.date,
                        child: Text('Date modified'),
                      ),
                      PopupMenuItem(
                        value: SortOption.name,
                        child: Text('Name'),
                      ),
                    ],
                  ),
                if (_isSearching)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close search',
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                      });
                      ref.read(libraryProvider.notifier).setSearchQuery('');
                    },
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.add),
                  tooltip: 'Create',
                  onSelected: (value) {
                    if (value == 'folder') createFolder();
                    if (value == 'scan') navigateToScan();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'scan',
                      child: Text('New scan'),
                    ),
                    PopupMenuItem(
                      value: 'folder',
                      child: Text('Create folder'),
                    ),
                  ],
                ),
                if (!widget.embedded)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
              ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(libraryProvider.notifier).loadPdfs(),
        child: libraryState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final pdfs = _viewAllInFolder ||
                          _isSearching ||
                          !libraryState.isAllDocuments
                      ? libraryState.visiblePdfs
                      : libraryState.recentPdfs;
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: LibraryBreadcrumb()),
                      SliverToBoxAdapter(child: LibraryFolderStrip(actions: this)),
                      if (_isSearching)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  libraryState.searchScopeLabel,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (!libraryState.isAllDocuments)
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Search all documents'),
                                    subtitle: const Text(
                                      'Include PDFs outside this folder',
                                    ),
                                    value: libraryState.searchAllDocuments,
                                    onChanged: (value) => ref
                                        .read(libraryProvider.notifier)
                                        .setSearchAllDocuments(value),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: libraryState.isAllDocuments && !_viewAllInFolder
                              ? 'Recent Documents'
                              : libraryState.isAllDocuments
                                  ? 'All Documents'
                                  : 'Documents',
                          subtitle: libraryState.isAllDocuments
                              ? 'Across your whole library'
                              : 'In ${libraryState.currentFolderName}',
                          actionLabel: libraryState.isAllDocuments
                              ? (_viewAllInFolder ? 'Recents' : 'View All')
                              : null,
                          onAction: libraryState.isAllDocuments
                              ? () => setState(
                                    () => _viewAllInFolder = !_viewAllInFolder,
                                  )
                              : null,
                        ),
                      ),
                      if (pdfs.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: LibraryEmptyState(
                            searching: libraryState.searchQuery.isNotEmpty,
                            query: libraryState.searchQuery,
                            inFolder: !libraryState.isAllDocuments,
                            onScan: navigateToScan,
                            onCreateFolder: createFolder,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _gridCount(constraints.maxWidth),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
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
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
