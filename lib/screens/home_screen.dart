import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paperwise_pdf_maker/providers/pdf_provider.dart';
import 'package:paperwise_pdf_maker/screens/pdf_viewer_screen.dart';
import 'package:paperwise_pdf_maker/screens/scan_screen.dart';
import 'package:paperwise_pdf_maker/screens/settings_screen.dart';
import 'package:paperwise_pdf_maker/widgets/pdf_list_item.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<PdfProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToScanScreen() async {
    final bool? pdfCreated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );

    if (pdfCreated == true && mounted) {
      context.read<PdfProvider>().loadPdfs();
    }
  }

  void _openPDF(File pdfFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(pdfFile: pdfFile),
      ),
    );
  }

  Future<void> _renamePdf(File pdfFile) async {
    final fileName = path.basenameWithoutExtension(pdfFile.path);
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
      try {
        final dir = pdfFile.parent;
        final newFile = File('${dir.path}/$newName');
        await pdfFile.rename(newFile.path);
        context.read<PdfProvider>().loadPdfs();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to rename PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePDF(File pdfFile, int index) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF?'),
        content:
            Text('Are you sure you want to delete "${path.basename(pdfFile.path)}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      context.read<PdfProvider>().deletePdf(pdfFile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${path.basename(pdfFile.path)}" deleted.')),
      );
    }
  }

  Future<void> _sharePdf(File pdfFile) async {
    try {
      await Share.shareXFiles([
        XFile(pdfFile.path)
      ], subject: 'Sharing ${path.basename(pdfFile.path)}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share PDF')),
      );
    }
  }

  Future<void> _deleteSelectedPDFs(PdfProvider provider) async {
    final selectedCount = provider.selectedCount;
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected PDFs?'),
        content: Text('Are you sure you want to delete $selectedCount ${selectedCount == 1 ? 'PDF' : 'PDFs'}?'),
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
      await provider.deleteSelectedPdfs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$selectedCount ${selectedCount == 1 ? 'PDF' : 'PDFs'} deleted')),
        );
      }
    }
  }

  Future<void> _shareSelectedPDFs(PdfProvider provider) async {
    final selectedPdfs = provider.getSelectedPdfs();
    try {
      await Share.shareXFiles(
        selectedPdfs.map((pdf) => XFile(pdf.path)).toList(),
        subject: 'Sharing ${selectedPdfs.length} ${selectedPdfs.length == 1 ? 'PDF' : 'PDFs'}',
      );
      provider.clearSelection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share PDFs')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfProvider = context.watch<PdfProvider>();
    final isSelectionMode = pdfProvider.isSelectionMode;
    final selectedCount = pdfProvider.selectedCount;
    final colorScheme = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        if (isSelectionMode) {
          pdfProvider.toggleSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => pdfProvider.toggleSelectionMode(),
                )
              : null,
          title: isSelectionMode
              ? Text('$selectedCount selected')
              : const Text('Paperwise'),
          actions: [
            if (isSelectionMode) ...[
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: selectedCount > 0
                    ? () => _shareSelectedPDFs(pdfProvider)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: selectedCount > 0
                    ? () => _deleteSelectedPDFs(pdfProvider)
                    : null,
              ),
            ] else
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
          ],
          bottom: !isSelectionMode ? PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search PDFs...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: PopupMenuButton<SortOption>(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sort PDFs',
                    onSelected: (option) => pdfProvider.setSortOption(option),
                    itemBuilder: (context) => [
                      CheckedPopupMenuItem(
                        value: SortOption.date,
                        checked: pdfProvider.sortOption == SortOption.date,
                        child: const Text('Sort by Date'),
                      ),
                      CheckedPopupMenuItem(
                        value: SortOption.name,
                        checked: pdfProvider.sortOption == SortOption.name,
                        child: const Text('Sort by Name'),
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                ),
              ),
            ),
          ) : null,
        ),
        floatingActionButton: !isSelectionMode
            ? FloatingActionButton.extended(
                onPressed: _navigateToScanScreen,
                label: const Text('New Scan'),
                icon: const Icon(Icons.add_a_photo_outlined),
              ).animate().slideY(begin: 1.5, duration: 400.ms, curve: Curves.easeOut).fadeIn()
            : null,
        body: RefreshIndicator(
          onRefresh: () => pdfProvider.loadPdfs(),
          child: pdfProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : pdfProvider.pdfs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      key: _listKey,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: pdfProvider.pdfs.length,
                      itemBuilder: (context, index) {
                        final pdfFile = pdfProvider.pdfs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: PdfListItem(
                            pdfFile: pdfFile,
                            onTap: () => _openPDF(pdfFile),
                            onDelete: () => _deletePDF(pdfFile, index),
                            onRename: () => _renamePdf(pdfFile),
                            onShare: () => _sharePdf(pdfFile),
                            onEdit: () => _openPDF(pdfFile),
                            onCrop: () => _openPDF(pdfFile),
                          ).animate().fadeIn(duration: 300.ms, delay: (100 * index).ms).slideX(begin: -0.2),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.find_in_page_outlined,
            size: 80,
            color: colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? 'No PDFs Yet' : 'No Results Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Tap "New Scan" to create your first PDF'
                : 'Try a different search term',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }
}