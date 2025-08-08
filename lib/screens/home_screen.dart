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

  Future<void> _shareSelectedPDFs() async {
    final selectedPdfs = context.read<PdfProvider>().getSelectedPdfs();
    try {
      await Share.shareXFiles(
        selectedPdfs.map((pdf) => XFile(pdf.path)).toList(),
        subject: 'Sharing ${selectedPdfs.length} ${selectedPdfs.length == 1 ? 'PDF' : 'PDFs'}',
      );
      context.read<PdfProvider>().clearSelection();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paperwise'),
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
                  onPressed: () => _deleteSelectedPDFs(pdfProvider),
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
            ).animate().slideY(begin: 1.5, duration: 400.ms, curve: Curves.easeOut).fadeIn()
          : null,
      body: RefreshIndicator(
        onRefresh: () => pdfProvider.loadPdfs(),
        child: pdfProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : pdfProvider.pdfs.isEmpty
                ? _HomeEmptyState(searchText: _searchController.text)
                : _PdfListView(
                    pdfs: pdfProvider.pdfs,
                    onOpen: _openPDF,
                    onDelete: _deletePDF,
                    onRename: _renamePdf,
                    onShare: _sharePdf,
                    onEdit: _openPDF,
                    onCrop: _openPDF,
                    onShareSelected: _shareSelectedPDFs,
                    onDeleteSelected: () => _deleteSelectedPDFs(pdfProvider),
                    isSelectionMode: isSelectionMode,
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
  final List<File> pdfs;
  final void Function(File pdfFile) onOpen;
  final void Function(File pdfFile, int index) onDelete;
  final void Function(File pdfFile) onRename;
  final void Function(File pdfFile) onShare;
  final void Function(File pdfFile) onEdit;
  final void Function(File pdfFile) onCrop;
  final void Function() onShareSelected;
  final void Function() onDeleteSelected;
  final bool isSelectionMode;
  const _PdfListView({required this.pdfs, required this.onOpen, required this.onDelete, required this.onRename, required this.onShare, required this.onEdit, required this.onCrop, required this.onShareSelected, required this.onDeleteSelected, required this.isSelectionMode});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: pdfs.length,
      itemBuilder: (context, index) {
        final pdfFile = pdfs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: PdfListItem(
            pdfFile: pdfFile,
            onTap: () => onOpen(pdfFile),
            onDelete: () => onDelete(pdfFile, index),
            onRename: () => onRename(pdfFile),
            onShare: () => onShare(pdfFile),
            onEdit: () => onEdit(pdfFile),
            onCrop: () => onCrop(pdfFile),
          ).animate().fadeIn(duration: 300.ms, delay: (100 * index).ms).slideX(begin: -0.2),
        );
      },
    );
  }
}