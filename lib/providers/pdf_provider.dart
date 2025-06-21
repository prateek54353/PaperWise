import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum SortOption { date, name }

class PdfProvider with ChangeNotifier {
  List<File> _pdfs = [];
  bool _isLoading = false;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.date;

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
  SortOption get sortOption => _sortOption;

  PdfProvider() {
    loadPdfs();
  }

  Future<void> loadPdfs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final files = appDocDir.listSync()
          .where((file) => file.path.toLowerCase().endsWith('.pdf') && file is File)
          .cast<File>()
          .toList();

      // Sort by date modified (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      _pdfs = files;
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