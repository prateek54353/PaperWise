import 'dart:async';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/models/failure.dart';
import 'package:paperwise_pdf_maker/core/services/trash_service.dart';
import 'package:paperwise_pdf_maker/features/library/application/library_facade.dart';
import 'package:paperwise_pdf_maker/features/library/data/datasources/local_pdf_datasource.dart';
import 'package:paperwise_pdf_maker/features/library/data/repositories/pdf_repository_impl.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/folder_entity.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/domain/repositories/pdf_repository.dart'
    show PdfRepository, SortOption;

class LibraryCrumb {
  const LibraryCrumb({required this.label, required this.relativePath});

  final String label;

  /// `null` is the virtual All Documents view.
  final String? relativePath;
}

/// `null` means the virtual All Documents view (every PDF in the library).
/// An empty string means files sitting in the PDF root directory.
class LibraryState {
  final List<PdfEntity> pdfs;
  final List<FolderEntity> folders;
  final String? currentFolderRelative;
  final bool isLoading;
  final Failure? error;
  final Set<String> selectedPdfPaths;
  final bool isSelectionMode;
  final SortOption sortOption;
  final String searchQuery;
  final bool searchAllDocuments;

  const LibraryState({
    this.pdfs = const [],
    this.folders = const [],
    this.currentFolderRelative,
    this.isLoading = false,
    this.error,
    this.selectedPdfPaths = const {},
    this.isSelectionMode = false,
    this.sortOption = SortOption.date,
    this.searchQuery = '',
    this.searchAllDocuments = false,
  });

  bool get isAllDocuments => currentFolderRelative == null;

  bool get isLibraryRoot => currentFolderRelative == '';

  String get currentFolderName {
    if (isAllDocuments) return 'All Documents';
    if (isLibraryRoot) return 'Library';
    final parts = currentFolderRelative!.split('/');
    return parts.last;
  }

  String get searchScopeLabel {
    if (searchAllDocuments || isAllDocuments) {
      return 'Searching all documents';
    }
    return 'Searching in $currentFolderName';
  }

  List<LibraryCrumb> get breadcrumbs {
    final crumbs = <LibraryCrumb>[
      const LibraryCrumb(label: 'All Documents', relativePath: null),
    ];
    final current = currentFolderRelative;
    if (current == null) return crumbs;
    if (current.isEmpty) {
      crumbs.add(const LibraryCrumb(label: 'Library', relativePath: ''));
      return crumbs;
    }
    final parts = current.split('/');
    var accumulated = '';
    for (final part in parts) {
      accumulated = accumulated.isEmpty ? part : '$accumulated/$part';
      crumbs.add(LibraryCrumb(label: part, relativePath: accumulated));
    }
    return crumbs;
  }

  List<PdfEntity> get folderPdfs {
    if (isAllDocuments) return List<PdfEntity>.from(pdfs);
    final folder = currentFolderRelative ?? '';
    return pdfs.where((pdf) => pdf.folderRelativePath == folder).toList();
  }

  List<PdfEntity> get visiblePdfs {
    var items = searchAllDocuments || isAllDocuments
        ? List<PdfEntity>.from(pdfs)
        : folderPdfs;

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      items = items
          .where((pdf) => pdf.name.toLowerCase().contains(query))
          .toList();
    }

    if (sortOption == SortOption.name) {
      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else {
      items.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    }
    return items;
  }

  List<PdfEntity> get sortedPdfs => visiblePdfs;

  List<PdfEntity> get recentPdfs {
    final source = isAllDocuments ? pdfs : folderPdfs;
    final sorted = List<PdfEntity>.from(source)
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return sorted.take(12).toList();
  }

  FolderEntity get allDocumentsFolder => FolderEntity(
        relativePath: '',
        name: 'All Documents',
        documentCount: pdfs.length,
        isVirtualAll: true,
      );

  int get selectedCount => selectedPdfPaths.length;

  bool isPdfSelected(PdfEntity pdf) =>
      selectedPdfPaths.contains(pdf.relativePath);

  List<PdfEntity> get selectedPdfs {
    return pdfs.where((pdf) => selectedPdfPaths.contains(pdf.relativePath)).toList();
  }

  String get saveFolderRelative => currentFolderRelative ?? '';

  LibraryState copyWith({
    List<PdfEntity>? pdfs,
    List<FolderEntity>? folders,
    String? currentFolderRelative,
    bool clearCurrentFolder = false,
    bool? isLoading,
    Failure? error,
    Set<String>? selectedPdfPaths,
    bool? isSelectionMode,
    SortOption? sortOption,
    String? searchQuery,
    bool? searchAllDocuments,
  }) {
    return LibraryState(
      pdfs: pdfs ?? this.pdfs,
      folders: folders ?? this.folders,
      currentFolderRelative: clearCurrentFolder
          ? null
          : currentFolderRelative ?? this.currentFolderRelative,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedPdfPaths: selectedPdfPaths ?? this.selectedPdfPaths,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      sortOption: sortOption ?? this.sortOption,
      searchQuery: searchQuery ?? this.searchQuery,
      searchAllDocuments: searchAllDocuments ?? this.searchAllDocuments,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final LibraryFacade facade;
  Timer? _searchDebounce;

  LibraryNotifier(this.facade) : super(const LibraryState()) {
    loadPdfs();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadPdfs() async {
    state = state.copyWith(isLoading: true);
    final pdfResult = await facade.getPdfs();
    final parent = state.currentFolderRelative ?? '';
    final folderResult = await facade.getFolders(parentRelative: parent);

    pdfResult.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure),
      (pdfs) {
        folderResult.fold(
          (failure) => state = state.copyWith(
            isLoading: false,
            pdfs: pdfs,
            error: failure,
          ),
          (folders) => state = state.copyWith(
            isLoading: false,
            pdfs: pdfs,
            folders: folders,
          ),
        );
      },
    );
  }

  Future<void> _refreshFolders() async {
    final parent = state.currentFolderRelative ?? '';
    final result = await facade.getFolders(parentRelative: parent);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (folders) => state = state.copyWith(folders: folders, error: null),
    );
  }

  Future<void> openAllDocuments() async {
    state = state.copyWith(clearCurrentFolder: true);
    await loadPdfs();
  }

  Future<void> openFolder(String? folderRelative) async {
    if (folderRelative == null) {
      await openAllDocuments();
      return;
    }
    state = state.copyWith(currentFolderRelative: folderRelative);
    await loadPdfs();
  }

  Future<void> navigateUp() async {
    final current = state.currentFolderRelative;
    if (current == null || current.isEmpty) {
      await openAllDocuments();
      return;
    }
    final separator = current.lastIndexOf('/');
    if (separator <= 0) {
      await openAllDocuments();
      return;
    }
    await openFolder(current.substring(0, separator));
  }

  Future<Either<Failure, FolderEntity>> createFolder(
    String name, {
    String? parentRelative,
  }) async {
    final parent = parentRelative ?? state.currentFolderRelative ?? '';
    final result = await facade.createFolder(parent, name);
    await result.fold((_) async {}, (_) async => loadPdfs());
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) {},
    );
    return result;
  }

  Future<Either<Failure, FolderEntity>> createSubfolder(
    String parentRelative,
    String name,
  ) async {
    final result = await facade.createFolder(parentRelative, name);
    await result.fold((_) async {}, (_) async => loadPdfs());
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) {},
    );
    return result;
  }

  Future<Either<Failure, FolderEntity>> renameFolder(
    FolderEntity folder,
    String newName,
  ) async {
    final result = await facade.renameFolder(folder.relativePath, newName);
    await result.fold((_) async {}, (updated) async {
      if (state.currentFolderRelative == folder.relativePath) {
        state = state.copyWith(currentFolderRelative: updated.relativePath);
      }
      await loadPdfs();
    });
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) {},
    );
    return result;
  }

  Future<Either<Failure, void>> deleteFolder(
    FolderEntity folder, {
    required bool recursive,
  }) async {
    final result = await facade.deleteFolder(
      folder.relativePath,
      recursive: recursive,
    );
    await result.fold((_) async {}, (_) async {
      if (state.currentFolderRelative == folder.relativePath) {
        await navigateUp();
      } else {
        await loadPdfs();
      }
    });
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) {},
    );
    return result;
  }

  Future<Either<Failure, void>> moveFolder(
    FolderEntity folder,
    String destinationParent,
  ) async {
    final result =
        await facade.moveFolder(folder.relativePath, destinationParent);
    await result.fold((_) async {}, (_) async => loadPdfs());
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) {},
    );
    return result;
  }

  Future<Either<Failure, List<PdfEntity>>> movePdfsToFolder(
    List<PdfEntity> pdfs,
    String destinationFolder,
  ) async {
    final result = await facade.movePdfs(pdfs, destinationFolder);
    await result.fold(
      (failure) async {
        state = state.copyWith(error: failure);
        await loadPdfs();
      },
      (updated) async {
        state = state.copyWith(
          pdfs: updated,
          selectedPdfPaths: {},
          isSelectionMode: false,
          error: null,
        );
        await _refreshFolders();
      },
    );
    return result;
  }

  Future<void> deletePdf(PdfEntity pdf) async {
    await TrashService.moveToTrash(pdf.file);

    final result = await facade.deletePdf(pdf);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) {
        final updatedPdfs = List<PdfEntity>.from(state.pdfs);
        updatedPdfs.removeWhere((p) => p.relativePath == pdf.relativePath);
        state = state.copyWith(pdfs: updatedPdfs, error: null);
      },
    );
    await _refreshFolders();
  }

  Future<void> undoDeletePdf(PdfEntity pdf) async {
    final restored = await TrashService.restoreFromTrash(pdf.file.path);

    if (restored) {
      await loadPdfs();
    } else {
      state = state.copyWith(
        error: const FileSystemFailure('Could not restore PDF from trash'),
      );
    }
  }

  Future<void> deleteSelectedPdfs() async {
    final selected = state.selectedPdfs;
    final result = await facade.deletePdfs(selected);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) {
        final updatedPdfs = List<PdfEntity>.from(state.pdfs);
        for (final pdf in selected) {
          updatedPdfs.removeWhere((p) => p.relativePath == pdf.relativePath);
        }
        state = state.copyWith(
          pdfs: updatedPdfs,
          selectedPdfPaths: {},
          isSelectionMode: false,
        );
      },
    );
    await _refreshFolders();
  }

  Future<void> sharePdf(PdfEntity pdf) async {
    final result = await facade.sharePdf(pdf);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) => state = state.copyWith(error: null),
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
        final index = updatedPdfs
            .indexWhere((p) => p.relativePath == pdf.relativePath);
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
      (_) {},
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
    if (newSelection.contains(pdf.relativePath)) {
      newSelection.remove(pdf.relativePath);
      if (newSelection.isEmpty) {
        state = state.copyWith(
          selectedPdfPaths: newSelection,
          isSelectionMode: false,
        );
      } else {
        state = state.copyWith(selectedPdfPaths: newSelection);
      }
    } else {
      newSelection.add(pdf.relativePath);
      state = state.copyWith(
        selectedPdfPaths: newSelection,
        isSelectionMode: true,
      );
    }
  }

  void setSortOption(SortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query);
    });
  }

  void setSearchAllDocuments(bool value) {
    state = state.copyWith(searchAllDocuments: value);
  }

  void selectAll() {
    final allPaths = state.visiblePdfs.map((pdf) => pdf.relativePath).toSet();
    state = state.copyWith(
      selectedPdfPaths: allPaths,
      isSelectionMode: true,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selectedPdfPaths: {},
      isSelectionMode: false,
    );
  }

  Future<Either<Failure, PdfEntity>> savePdfBytes(
    Uint8List pdfBytes,
    String fileName, {
    String? folderRelative,
  }) async {
    final folder = folderRelative ?? state.saveFolderRelative;
    final result = await facade.savePdfBytes(
      pdfBytes,
      fileName,
      folderRelative: folder,
    );
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (pdfEntity) {
        final updatedPdfs = List<PdfEntity>.from(state.pdfs);
        updatedPdfs.add(pdfEntity);
        state = state.copyWith(pdfs: updatedPdfs, error: null);
      },
    );
    await _refreshFolders();
    return result;
  }

  Future<Either<Failure, PdfEntity>> mergePdfs(
    List<PdfEntity> pdfs,
    String outputName,
  ) async {
    final result = await facade.mergePdfs(
      pdfs,
      outputName,
      folderRelative: state.saveFolderRelative,
    );
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) {
        loadPdfs();
      },
    );
    return result;
  }
}

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

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final facade = ref.watch(libraryFacadeProvider);
  return LibraryNotifier(facade);
});
