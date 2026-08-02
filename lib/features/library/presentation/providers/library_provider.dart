import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import 'package:paperwise_pdf_maker/features/library/application/library_facade.dart';
import 'package:paperwise_pdf_maker/features/library/data/datasources/local_pdf_datasource.dart';
import 'package:paperwise_pdf_maker/features/library/data/repositories/pdf_repository_impl.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/domain/repositories/pdf_repository.dart' show PdfRepository, SortOption;

// State
class LibraryState {
  final List<PdfEntity> pdfs;
  final bool isLoading;
  final Failure? error;
  final Set<String> selectedPdfPaths;
  final bool isSelectionMode;
  final String searchQuery;
  final SortOption sortOption;

  const LibraryState({
    this.pdfs = const [],
    this.isLoading = false,
    this.error,
    this.selectedPdfPaths = const {},
    this.isSelectionMode = false,
    this.searchQuery = '',
    this.sortOption = SortOption.date,
  });

  List<PdfEntity> get filteredPdfs {
    var filtered = pdfs.where((pdf) {
      return pdf.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    if (sortOption == SortOption.name) {
      filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      filtered.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    }

    return filtered;
  }

  int get selectedCount => selectedPdfPaths.length;

  bool isPdfSelected(PdfEntity pdf) => selectedPdfPaths.contains(pdf.file.path);

  List<PdfEntity> get selectedPdfs {
    return pdfs.where((pdf) => selectedPdfPaths.contains(pdf.file.path)).toList();
  }

  LibraryState copyWith({
    List<PdfEntity>? pdfs,
    bool? isLoading,
    Failure? error,
    Set<String>? selectedPdfPaths,
    bool? isSelectionMode,
    String? searchQuery,
    SortOption? sortOption,
  }) {
    return LibraryState(
      pdfs: pdfs ?? this.pdfs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedPdfPaths: selectedPdfPaths ?? this.selectedPdfPaths,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

// Notifier
class LibraryNotifier extends StateNotifier<LibraryState> {
  final LibraryFacade facade;

  LibraryNotifier(this.facade) : super(const LibraryState()) {
    loadPdfs();
  }

  Future<void> loadPdfs() async {
    state = state.copyWith(isLoading: true);
    final result = await facade.getPdfs();
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure),
      (pdfs) => state = state.copyWith(isLoading: false, pdfs: pdfs),
    );
  }

  Future<void> deletePdf(PdfEntity pdf) async {
    final result = await facade.deletePdf(pdf);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) {
        final updatedPdfs = List<PdfEntity>.from(state.pdfs);
        updatedPdfs.removeWhere((p) => p.file.path == pdf.file.path);
        state = state.copyWith(pdfs: updatedPdfs);
      },
    );
  }

  Future<void> deleteSelectedPdfs() async {
    final selected = state.selectedPdfs;
    final result = await facade.deletePdfs(selected);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) {
        final updatedPdfs = List<PdfEntity>.from(state.pdfs);
        for (final pdf in selected) {
          updatedPdfs.removeWhere((p) => p.file.path == pdf.file.path);
        }
        state = state.copyWith(
          pdfs: updatedPdfs,
          selectedPdfPaths: {},
          isSelectionMode: false,
        );
      },
    );
  }

  Future<void> sharePdf(PdfEntity pdf) async {
    final result = await facade.sharePdf(pdf);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) => null, // Share doesn't change state
    );
  }

  Future<void> shareSelectedPdfs() async {
    for (final pdf in state.selectedPdfs) {
      await sharePdf(pdf);
    }
    state = state.copyWith(selectedPdfPaths: {}, isSelectionMode: false);
  }

  Future<void> renamePdf(PdfEntity pdf, String newName) async {
    final result = await facade.renamePdf(pdf, newName);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (updatedPdf) {
        final updatedPdfs = List<PdfEntity>.from(state.pdfs);
        final index = updatedPdfs.indexWhere((p) => p.file.path == pdf.file.path);
        if (index != -1) {
          updatedPdfs[index] = updatedPdf;
        }
        state = state.copyWith(pdfs: updatedPdfs);
      },
    );
  }

  Future<void> downloadPdf(PdfEntity pdf) async {
    final result = await facade.downloadPdf(pdf);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (downloadedPdf) => null, // Download doesn't change state
    );
  }

  void toggleSelectionMode() {
    final newMode = !state.isSelectionMode;
    state = state.copyWith(
      isSelectionMode: newMode,
      selectedPdfPaths: newMode ? {} : state.selectedPdfPaths,
    );
  }

  void togglePdfSelection(PdfEntity pdf) {
    final newSelection = Set<String>.from(state.selectedPdfPaths);
    if (newSelection.contains(pdf.file.path)) {
      newSelection.remove(pdf.file.path);
      if (newSelection.isEmpty) {
        state = state.copyWith(selectedPdfPaths: newSelection, isSelectionMode: false);
      } else {
        state = state.copyWith(selectedPdfPaths: newSelection);
      }
    } else {
      newSelection.add(pdf.file.path);
      state = state.copyWith(selectedPdfPaths: newSelection, isSelectionMode: true);
    }
  }

  void clearSelection() {
    state = state.copyWith(selectedPdfPaths: {}, isSelectionMode: false);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortOption(SortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final pdfDataSourceProvider = Provider<PdfDataSource>((ref) {
  return LocalPdfDataSource();
});

final pdfRepositoryProvider = Provider<PdfRepository>((ref) {
  final dataSource = ref.watch(pdfDataSourceProvider);
  return PdfRepositoryImpl(dataSource);
});

final libraryFacadeProvider = Provider<LibraryFacade>((ref) {
  final repository = ref.watch(pdfRepositoryProvider);
  return LibraryFacade(repository);
});

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final facade = ref.watch(libraryFacadeProvider);
  return LibraryNotifier(facade);
});
