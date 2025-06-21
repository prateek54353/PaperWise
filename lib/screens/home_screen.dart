import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paperwise_pdf_maker/providers/pdf_provider.dart';
import 'package:paperwise_pdf_maker/screens/scan_screen.dart';
import 'package:paperwise_pdf_maker/screens/settings_screen.dart';
import 'package:paperwise_pdf_maker/services/pdf_service.dart'; // Import PDFService
import 'package:paperwise_pdf_maker/widgets/pdf_list_item.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final TextEditingController _searchController = TextEditingController();
  final PDFService _pdfService = PDFService(); // Create an instance of PDFService

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

  // MODIFIED: This method now opens the PDF externally
  void _previewPDF(File pdfFile) async {
    try {
      await _pdfService.openPdfExternal(pdfFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file. No PDF viewer app found?')),
        );
      }
    }
  }

  Future<void> _deletePDF(File pdfFile, int index) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF?'),
        content:
            Text('Are you sure you want to delete "${pdfFile.path.split('/').last}"?'),
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
        SnackBar(content: Text('"${pdfFile.path.split('/').last}" deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfProvider = context.watch<PdfProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paperwise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToScanScreen,
        label: const Text('New Scan'),
        icon: const Icon(Icons.add_a_photo_outlined),
      ).animate().slideY(begin: 1.5, duration: 400.ms, curve: Curves.easeOut).fadeIn(),
      body: RefreshIndicator(
        onRefresh: () => pdfProvider.loadPdfs(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                          hintText: 'Search PDFs...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          contentPadding: EdgeInsets.zero),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<SortOption>(
                    icon: const Icon(Icons.sort),
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
                  )
                ],
              ),
            ),
            Expanded(
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
                            return PdfListItem(
                              pdfFile: pdfFile,
                              onTap: () => _previewPDF(pdfFile),
                              onDelete: () => _deletePDF(pdfFile, index),
                            ).animate().fadeIn(duration: 300.ms, delay: (100 * index).ms).slideX(begin: -0.2);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.find_in_page_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? 'No Scans Yet' : 'No Results Found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Tap "New Scan" to create your first PDF.'
                : 'Try a different search term.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }
}