import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paperwise_pdf_maker/providers/settings_provider.dart';
import 'package:paperwise_pdf_maker/services/pdf_service.dart';
import 'package:paperwise_pdf_maker/widgets/image_preview_card.dart';
import 'package:provider/provider.dart';
// The 'image' package import is no longer needed and has been removed.
import 'package:intl/intl.dart';

enum PageSizeMode { fit, a4, letter, legal }

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
  PageSizeMode _pageSizeMode = PageSizeMode.a4;

  // The _rotateImage method has been completely removed.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.aspect_ratio_outlined),
            tooltip: 'Page Size',
            onPressed: _selectedImages.isEmpty ? null : _showPageSizeDialog,
          ),
        ],
      ),
      floatingActionButton: _selectedImages.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddImageModal,
              child: const Icon(Icons.add),
            )
          : null,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _selectedImages.isEmpty
                    ? _buildEmptyState()
                    : _buildImageGrid(),
              ),
              _buildGeneratePdfButton(),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_processingStatus, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return ReorderableGridView.builder(
      padding: const EdgeInsets.all(12.0), // Increased padding for a better look
      itemCount: _selectedImages.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final item = _selectedImages.removeAt(oldIndex);
          _selectedImages.insert(newIndex, item);
          HapticFeedback.mediumImpact();
        });
      },
      // MODIFIED: This delegate creates an adaptive grid.
      // It makes columns with a maximum width of 180 pixels,
      // resulting in ~2 columns on most phones, making thumbnails larger.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final imageFile = _selectedImages[index];
        return ImagePreviewCard(
          key: ValueKey(imageFile.path),
          image: imageFile,
          index: index,
          onDelete: () {
            setState(() {
              _selectedImages.removeAt(index);
            });
          },
          onTap: () => _cropImage(index),
          // The onRotate callback has been removed.
        );
      },
    );
  }
  
  // --- Other helper methods (_pickImage, _generatePDF, dialogs, etc.) remain unchanged ---

  Future<void> _generatePDF() async {
    if (_selectedImages.isEmpty) return;
    final pdfName = await _showPdfNameDialog();
    if (pdfName == null || pdfName.isEmpty || !mounted) return;

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Generating PDF...';
    });

    try {
      await _pdfService.createPDF(_selectedImages, pdfName, _pageSizeMode);
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile>? pickedFiles;

      if (source == ImageSource.gallery) {
        pickedFiles = await picker.pickMultiImage();
      } else {
        final XFile? image = await picker.pickImage(source: source);
        pickedFiles = image == null ? null : [image];
      }

      if (pickedFiles == null || pickedFiles.isEmpty || !mounted) return;
      setState(() { _isProcessing = true; _processingStatus = 'Compressing images...'; });
      final quality = context.read<SettingsProvider>().settings.compressionQuality;
      final List<File> processedImages = [];
      for (var xFile in pickedFiles) {
        final compressedFile = await _compressImage(File(xFile.path), quality);
        if (compressedFile != null) { processedImages.add(compressedFile); }
      }
      setState(() { _selectedImages.addAll(processedImages); _isProcessing = false; _processingStatus = ''; });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isProcessing = false);
    }
  }
  
  Future<File?> _compressImage(File file, int quality) async {
     final tempDir = await getTemporaryDirectory();
     final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
     final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(file.absolute.path, targetPath, quality: quality, format: CompressFormat.jpeg);
     if (compressedXFile == null) return null;
     return File(compressedXFile.path);
  }

  Future<void> _cropImage(int index) async {
    final imageFile = _selectedImages[index];
    CroppedFile? croppedFile = await ImageCropper().cropImage(sourcePath: imageFile.path, uiSettings: [ AndroidUiSettings(toolbarTitle: 'Edit Image', toolbarColor: Theme.of(context).primaryColor, toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.original, lockAspectRatio: false), IOSUiSettings(title: 'Edit Image')]);
    if (croppedFile != null && mounted) {
      final quality = context.read<SettingsProvider>().settings.compressionQuality;
      final compressedFile = await _compressImage(File(croppedFile.path), quality);
      if (compressedFile != null) { setState(() => _selectedImages[index] = compressedFile); }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_photo_alternate_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Select images to create a PDF', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Select from Gallery')),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Take Photo')),
        ],
      ),
    );
  }

  Widget _buildGeneratePdfButton() {
     return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: _isProcessing || _selectedImages.isEmpty ? null : _generatePDF,
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Generate PDF'),
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), textStyle: const TextStyle(fontSize: 18)),
      ),
    );
  }

  void _showAddImageModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Add from Gallery'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
            ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Add from Camera'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
          ],
        ),
      ),
    );
  }

  void _showPageSizeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Page Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: PageSizeMode.values.map((mode) {
              return RadioListTile<PageSizeMode>(
                title: Text(mode.name[0].toUpperCase() + mode.name.substring(1)),
                value: mode,
                groupValue: _pageSizeMode,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _pageSizeMode = value;
                    });
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
          ],
        );
      },
    );
  }

  Future<String?> _showPdfNameDialog() {
    final controller = TextEditingController();
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    controller.text = 'Scan_$formattedDate';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Name your PDF'),
              content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: 'Enter PDF name', border: const OutlineInputBorder(), errorText: controller.text.trim().isEmpty ? 'Name cannot be empty' : null), onChanged: (value) => setState(() {})),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(onPressed: controller.text.trim().isEmpty ? null : () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
              ],
            );
          },
        );
      },
    );
  }
}