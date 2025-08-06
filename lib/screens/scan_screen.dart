import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paperwise_pdf_maker/providers/settings_provider.dart';
import 'package:paperwise_pdf_maker/services/pdf_service.dart';
import 'package:paperwise_pdf_maker/widgets/image_preview_card.dart';
import 'package:provider/provider.dart';

import 'package:paperwise_pdf_maker/models/app_settings.dart';
import 'package:path/path.dart' as path;
import 'package:paperwise_pdf_maker/models/page_size_mode.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final List<File> _selectedImages = [];
  final PDFService _pdfService = PDFService();
  bool _isProcessing = false;
  String _processingStatus = '';
  PageSizeMode _pageSizeMode = PageSizeMode.fit;
  String _scanName = 'New Scan';

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    if (settings.enableTempCleanup) {
      _pdfService.cleanupOldTempFiles(maxAge: settings.tempCleanupPeriod);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _renameScan,
          child: Row(
            children: [
              Expanded(
                child: Text(_scanName),
              ),
              const Icon(Icons.edit_outlined, size: 16),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.aspect_ratio_outlined),
            label: Text(_pageSizeMode.displayName),
            onPressed: _showPageSizeDialog,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImages.isNotEmpty)
            FloatingActionButton(
              onPressed: _showAddImageModal,
              heroTag: 'addMore',
              child: const Icon(Icons.add),
            ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: _selectedImages.isEmpty ? null : _generatePDF,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Generate PDF'),
            heroTag: 'generate',
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _selectedImages.isEmpty
                      ? _ScanEmptyState(onAddImage: _showAddImageModal)
                      : _ImageGrid(
                          selectedImages: _selectedImages,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (oldIndex < newIndex) newIndex -= 1;
                              final item = _selectedImages.removeAt(oldIndex);
                              _selectedImages.insert(newIndex, item);
                            });
                          },
                          onDelete: (index) {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          onCrop: (index) => _cropImage(index),
                        ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            _ProcessingOverlay(status: _processingStatus),
        ],
      ),
    );
  }

  Future<File?> _compressImage(File file, int quality) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(dir.path, '${path.basenameWithoutExtension(file.path)}_compressed.jpg');
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  Future<void> _cropImage(int index) async {
    final imageFile = _selectedImages[index];
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          showActivitySheetOnDone: false,
          showCancelConfirmationDialog: true,
          resetAspectRatioEnabled: true,
          aspectRatioPickerButtonHidden: false,
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    if (croppedFile != null && mounted) {
      final compressionLevel = context.read<SettingsProvider>().settings.compressionLevel;
      final compressedFile = await _compressImage(File(croppedFile.path), compressionLevel.quality);
      if (compressedFile != null) {
        setState(() => _selectedImages[index] = compressedFile);
      }
    }
  }

  Future<void> _showAddImageModal() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source != null && mounted) {
      final picker = ImagePicker();
      final compressionLevel = context.read<SettingsProvider>().settings.compressionLevel;

      if (source == ImageSource.gallery) {
        final pickedFiles = await picker.pickMultiImage();
        if (pickedFiles.isNotEmpty && mounted) {
          for (final pickedFile in pickedFiles) {
            final compressedFile = await _compressImage(File(pickedFile.path), compressionLevel.quality);
            if (compressedFile != null) {
              _selectedImages.add(compressedFile);
            }
          }
          setState(() {});
        }
      } else {
        final pickedFile = await picker.pickImage(source: source);
        if (pickedFile != null && mounted) {
          final compressedFile = await _compressImage(File(pickedFile.path), compressionLevel.quality);
          if (compressedFile != null) {
            setState(() => _selectedImages.add(compressedFile));
          }
        }
      }
    }
  }

  Future<void> _generatePDF() async {
    if (_selectedImages.isEmpty) return;

    // Only show name dialog if user hasn't renamed the scan
    String? pdfName;
    if (_scanName == 'New Scan') { // Check if default name is still present
      pdfName = await _showPdfNameDialog();
      if (pdfName == null || pdfName.isEmpty || !mounted) return;
    } else {
      pdfName = _scanName; // Use the custom scan name
    }

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Generating PDF...';
    });

    try {
      final fileName = '$pdfName.pdf';
      final settings = context.read<SettingsProvider>().settings;
      await _pdfService.createPdfFromImages(
        _selectedImages,
        fileName,
        pageSizeMode: _pageSizeMode,
        settings: settings,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generated successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _showPdfNameDialog() async {
    final now = DateTime.now();
    final defaultName = 'scan_${now.year}${now.month}${now.day}_${now.hour}${now.minute}';
    final controller = TextEditingController(text: defaultName);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save PDF'),
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
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameScan() async {
    final controller = TextEditingController(text: _scanName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Scan'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter scan name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      setState(() => _scanName = newName);
    }
  }

  void _showPageSizeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Page Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: PageSizeMode.values.map((mode) {
              return RadioListTile<PageSizeMode>(
                title: Text(mode.displayName),
                value: mode,
                groupValue: _pageSizeMode,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _pageSizeMode = value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  final String status;
  const _ProcessingOverlay({required this.status});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              status,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<File> selectedImages;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onDelete;
  final void Function(int index) onCrop;
  const _ImageGrid({required this.selectedImages, required this.onReorder, required this.onDelete, required this.onCrop});
  @override
  Widget build(BuildContext context) {
    return ReorderableGridView.builder(
      itemCount: selectedImages.length,
      onReorder: onReorder,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final imageFile = selectedImages[index];
        return ReorderableDragStartListener(
          key: ValueKey(imageFile.path),
          index: index,
          child: ImagePreviewCard(
            image: imageFile,
            index: index,
            onDelete: () => onDelete(index),
            onTap: () => onCrop(index),
            onCrop: () => onCrop(index),
          ),
        );
      },
    );
  }
}

class _ScanEmptyState extends StatelessWidget {
  final VoidCallback onAddImage;
  const _ScanEmptyState({required this.onAddImage});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_a_photo_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No images selected',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add images by taking a photo or\nchoosing from your gallery',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddImage,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add Images'),
          ),
        ],
      ),
    );
  }
}