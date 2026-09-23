import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/constants/app_constants.dart';
import 'package:paperwise_pdf_maker/core/utils/error_handler.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/pdf_merge_screen.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/pdf_split_screen.dart';
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
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
      ErrorHandler.showLoading(context, 'Renaming PDF...');
      
      await ref.read(libraryProvider.notifier).renamePdf(pdf, newName);
      await ref.read(libraryProvider.notifier).loadPdfs();
      
      if (mounted) {
        ErrorHandler.hideLoading(context);
        ErrorHandler.showSuccess(context, 'PDF renamed successfully');
      }
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
      ErrorHandler.showLoading(context, 'Deleting PDF...');
      
      await ref.read(libraryProvider.notifier).deletePdf(pdf);
      
      if (mounted) {
        ErrorHandler.hideLoading(context);
        ErrorHandler.showSuccess(context, '"${pdf.name}" deleted.');
      }
    }
  }

  Future<void> _sharePdf(PdfEntity pdf) async {
    ErrorHandler.showLoading(context, 'Preparing PDF for sharing...');
    
    await ref.read(libraryProvider.notifier).sharePdf(pdf);
    
    // Check for errors after the operation
    if (mounted) {
      final libraryState = ref.read(libraryProvider);
      ErrorHandler.hideLoading(context);
      
      if (libraryState.error != null) {
        ErrorHandler.showError(context, libraryState.error!);
        ref.read(libraryProvider.notifier).clearError();
      } else {
        ErrorHandler.showSuccess(context, 'Share sheet opened');
      }
    }
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
      ErrorHandler.showLoading(
        context, 
        'Deleting $selectedCount ${selectedCount == 1 ? 'PDF' : 'PDFs'}...',
        duration: const Duration(seconds: 60),
      );
      
      await ref.read(libraryProvider.notifier).deleteSelectedPdfs();
      
      if (mounted) {
        ErrorHandler.hideLoading(context);
        ErrorHandler.showSuccess(
          context, 
          '$selectedCount ${selectedCount == 1 ? 'PDF' : 'PDFs'} deleted',
        );
      }
    }
  }

  Future<void> _shareSelectedPDFs() async {
    final selectedCount = ref.read(libraryProvider).selectedCount;
    
    // Show loading indicator for batch operations
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text('Preparing $selectedCount ${selectedCount == 1 ? 'PDF' : 'PDFs'} for sharing...'),
          ],
        ),
        duration: const Duration(seconds: 60),
      ),
    );
    
    await ref.read(libraryProvider.notifier).shareSelectedPdfs();
    
    if (mounted) {
      messenger.clearSnackBars();
    }
  }

  void _mergeSelectedPDFs() {
    final selectedPdfs = ref.read(libraryProvider).selectedPdfs;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfMergeScreen(pdfs: selectedPdfs),
      ),
    );
  }

  void _splitPdf(PdfEntity pdf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfSplitScreen(pdf: pdf),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final isSelectionMode = libraryState.isSelectionMode;

    // Show error if present
    if (libraryState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorHandler.showError(context, libraryState.error!);
        ref.read(libraryProvider.notifier).clearError();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: isSelectionMode
            ? [
                if (libraryState.selectedCount >= 2)
                  IconButton(
                    icon: const Icon(Icons.merge_type),
                    tooltip: 'Merge Selected',
                    onPressed: _mergeSelectedPDFs,
                  ),
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
        onRefresh: () async {
          await ref.read(libraryProvider.notifier).loadPdfs();
          if (!mounted) return;
          final ctx = context;
          if (ctx.mounted) {
            ErrorHandler.showSuccess(ctx, 'Library refreshed');
          }
        },
        child: libraryState.isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading PDFs...'),
                  ],
                ),
              )
            : libraryState.sortedPdfs.isEmpty
                ? const _HomeEmptyState()
                : _PdfListView(
                    pdfs: libraryState.sortedPdfs,
                    onOpen: _openPDF,
                    onDelete: _deletePDF,
                    onRename: _renamePdf,
                    onShare: _sharePdf,
                    onSplit: _splitPdf,
                  ),
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState();

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
            'No PDFs Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "New Scan" to create your first PDF',
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
  final void Function(PdfEntity pdf)? onSplit;

  const _PdfListView({
    required this.pdfs,
    required this.onOpen,
    required this.onDelete,
    required this.onRename,
    required this.onShare,
    this.onSplit,
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
            onSplit: onSplit != null ? () => onSplit!(pdf) : null,
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: (100 * index).ms)
              .slideX(begin: -0.2),
        );
      },
    );
  }
}
