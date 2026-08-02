import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/constants/app_constants.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/pdf_viewer_screen.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/widgets/pdf_list_item.dart';
import 'package:paperwise_pdf_maker/features/settings/presentation/screens/settings_screen.dart';
import 'package:path/path.dart' as path;
import 'package:paperwise_pdf_maker/screens/scan_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(libraryProvider.notifier).setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _navigateToScanScreen() async {
    final createdPdf = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ScanScreen()),
    );

    if (createdPdf == true && mounted) {
      await ref.read(libraryProvider.notifier).loadPdfs();
    }
  }

  void _openPDF(PdfEntity pdf) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfViewerScreen(pdf: pdf),
      ),
    );
  }

  Future<void> _renamePdf(PdfEntity pdf) async {
    final fileName = path.basenameWithoutExtension(pdf.name);
    final controller = TextEditingController(text: fileName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename PDF'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'PDF Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, '$name.pdf');
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && mounted) {
      ref.read(libraryProvider.notifier).renamePdf(pdf, newName);
      ref.read(libraryProvider.notifier).loadPdfs();
    }
  }

  Future<void> _deletePDF(PdfEntity pdf) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF?'),
        content: Text('Are you sure you want to delete "${pdf.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      await ref.read(libraryProvider.notifier).deletePdf(pdf);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${pdf.name}" deleted.')),
        );
      }
    }
  }

  Future<void> _sharePdf(PdfEntity pdf) async {
    await ref.read(libraryProvider.notifier).sharePdf(pdf);
  }

  Future<void> _deleteSelectedPDFs() async {
    final selectedCount = ref.read(libraryProvider).selectedCount;
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected PDFs?'),
        content: Text(
            'Are you sure you want to delete $selectedCount ${selectedCount == 1 ? 'PDF' : 'PDFs'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      await ref.read(libraryProvider.notifier).deleteSelectedPdfs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '$selectedCount ${selectedCount == 1 ? 'PDF' : 'PDFs'} deleted')),
        );
      }
    }
  }

  Future<void> _shareSelectedPDFs() async {
    await ref.read(libraryProvider.notifier).shareSelectedPdfs();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final isSelectionMode = libraryState.isSelectionMode;
    final filteredPdfs = libraryState.filteredPdfs;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share Selected',
                  onPressed: _shareSelectedPDFs,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Selected',
                  onPressed: _deleteSelectedPDFs,
                ),
              ]
            : [
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
      floatingActionButton: !isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _navigateToScanScreen,
              label: const Text('New Scan'),
              icon: const Icon(Icons.add_a_photo_outlined),
            )
              .animate()
              .slideY(begin: 1.5, duration: 400.ms, curve: Curves.easeOut)
              .fadeIn()
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.read(libraryProvider.notifier).loadPdfs(),
        child: libraryState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredPdfs.isEmpty
                ? _HomeEmptyState(searchText: _searchController.text)
                : _PdfListView(
                    pdfs: filteredPdfs,
                    onOpen: _openPDF,
                    onDelete: _deletePDF,
                    onRename: _renamePdf,
                    onShare: _sharePdf,
                  ),
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  final String searchText;
  const _HomeEmptyState({required this.searchText});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.find_in_page_outlined,
            size: 80,
            color: colorScheme.secondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            searchText.isEmpty ? 'No PDFs Yet' : 'No Results Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            searchText.isEmpty
                ? 'Tap "New Scan" to create your first PDF'
                : 'Try a different search term',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }
}

class _PdfListView extends StatelessWidget {
  final List<PdfEntity> pdfs;
  final void Function(PdfEntity pdf) onOpen;
  final void Function(PdfEntity pdf) onDelete;
  final void Function(PdfEntity pdf) onRename;
  final void Function(PdfEntity pdf) onShare;

  const _PdfListView({
    required this.pdfs,
    required this.onOpen,
    required this.onDelete,
    required this.onRename,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: pdfs.length,
      itemBuilder: (context, index) {
        final pdf = pdfs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: PdfListItem(
            pdf: pdf,
            onTap: () => onOpen(pdf),
            onDelete: () => onDelete(pdf),
            onRename: () => onRename(pdf),
            onShare: () => onShare(pdf),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: (100 * index).ms)
              .slideX(begin: -0.2),
        );
      },
    );
  }
}
