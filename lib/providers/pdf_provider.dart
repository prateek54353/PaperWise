import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:paperwise_pdf_maker/services/pdf_service.dart';

enum SortOption { date, name }

class PdfProvider with ChangeNotifier {
  List<File> _pdfs = [];
  Set<String> _selectedPdfPaths = {};
  bool _isLoading = false;
  bool _isSelectionMode = false;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.date;
  final PDFService _pdfService = PDFService();

  List<File> get pdfs {
    List<File> filteredPdfs = _pdfs.where((pdf) {
      final pdfName = pdf.path.split('/').last.toLowerCase();
      return pdfName.contains(_searchQuery.toLowerCase());
    }).toList();

    if (_sortOption == SortOption.name) {
      filteredPdfs.sort((a, b) => a.path.split('/').last.toLowerCase().compareTo(b.path.split('/').last.toLowerCase()));
    }
    // Default sorting is by date (already sorted on load)
    
    return filteredPdfs;
  }
  
  bool get isLoading => _isLoading;
  bool get isSelectionMode => _isSelectionMode;
  SortOption get sortOption => _sortOption;
  Set<String> get selectedPdfPaths => _selectedPdfPaths;
  int get selectedCount => _selectedPdfPaths.length;

  bool isPdfSelected(File pdf) => _selectedPdfPaths.contains(pdf.path);

  PdfProvider() {
    loadPdfs();
  }

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      clearSelection();
    }
    notifyListeners();
  }

  void togglePdfSelection(File pdf) {
    if (_selectedPdfPaths.contains(pdf.path)) {
      _selectedPdfPaths.remove(pdf.path);
      if (_selectedPdfPaths.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedPdfPaths.add(pdf.path);
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedPdfPaths.clear();
    notifyListeners();
  }

  List<File> getSelectedPdfs() {
    return _pdfs.where((pdf) => _selectedPdfPaths.contains(pdf.path)).toList();
  }

  Future<void> deleteSelectedPdfs() async {
    final selectedPdfs = getSelectedPdfs();
    for (final pdf in selectedPdfs) {
      await deletePdf(pdf);
    }
    clearSelection();
    _isSelectionMode = false;
    notifyListeners();
  }

  Future<void> loadPdfs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final pdfDir = await _pdfService.getDefaultPdfDirectory();
      final dir = Directory(pdfDir);
      
      if (await dir.exists()) {
        final files = dir.listSync()
            .where((file) => file.path.toLowerCase().endsWith('.pdf') && file is File)
            .cast<File>()
            .toList();

        // Sort by date modified (newest first)
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        _pdfs = files;
      } else {
        _pdfs = [];
      }
    } catch (e) {
      debugPrint("Error loading PDFs: $e");
      _pdfs = [];
    }

    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> deletePdf(File pdfFile) async {
    try {
      await pdfFile.delete();
      final index = _pdfs.indexWhere((p) => p.path == pdfFile.path);
      if (index != -1) {
        _pdfs.removeAt(index);
        _selectedPdfPaths.remove(pdfFile.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error deleting PDF: $e");
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    if (option == SortOption.date) {
       _pdfs.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    }
    notifyListeners();
  }
}