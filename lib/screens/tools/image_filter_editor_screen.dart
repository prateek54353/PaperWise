import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum ScanImageFilter { original, auto, grayscale, blackAndWhite, sharpen }

extension on ScanImageFilter {
  String get label => switch (this) {
        ScanImageFilter.original => 'Original',
        ScanImageFilter.auto => 'Auto',
        ScanImageFilter.grayscale => 'Grayscale',
        ScanImageFilter.blackAndWhite => 'B/W',
        ScanImageFilter.sharpen => 'Sharpen',
      };
}

class ImageFilterEditorScreen extends StatefulWidget {
  final File imageFile;

  const ImageFilterEditorScreen({super.key, required this.imageFile});

  @override
  State<ImageFilterEditorScreen> createState() =>
      _ImageFilterEditorScreenState();
}

class _ImageFilterEditorScreenState extends State<ImageFilterEditorScreen> {
  static const _previewMaxWidth = 1400;

  Uint8List? _sourceBytes;
  Uint8List? _previewBytes;
  ScanImageFilter _selectedFilter = ScanImageFilter.original;
  bool _isLoading = true;
  bool _isPreviewLoading = false;
  bool _isSaving = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      _sourceBytes = await widget.imageFile.readAsBytes();
      await _updatePreview();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open image: $error')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _selectFilter(ScanImageFilter filter) async {
    if (_selectedFilter == filter || _isSaving) return;
    setState(() => _selectedFilter = filter);
    await _updatePreview();
  }

  Future<void> _updatePreview() async {
    final sourceBytes = _sourceBytes;
    if (sourceBytes == null) return;

    final requestId = ++_requestId;
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isPreviewLoading = true;
      });
    }

    try {
      final preview = await compute(
        _renderFilter,
        _FilterRequest(
          sourceBytes: sourceBytes,
          filter: _selectedFilter,
          maxWidth: _previewMaxWidth,
        ),
      );
      if (!mounted || requestId != _requestId) return;
      setState(() => _previewBytes = preview);
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not preview filter: $error')),
      );
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isPreviewLoading = false);
      }
    }
  }

  Future<void> _applyFilter() async {
    final sourceBytes = _sourceBytes;
    if (sourceBytes == null || _isSaving) return;

    if (_selectedFilter == ScanImageFilter.original) {
      Navigator.pop(context, widget.imageFile);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final outputBytes = await compute(
        _renderFilter,
        _FilterRequest(sourceBytes: sourceBytes, filter: _selectedFilter),
      );
      final temporaryDirectory = await getTemporaryDirectory();
      final outputFile = File(
        path.join(
          temporaryDirectory.path,
          'paperwise_filter_${DateTime.now().microsecondsSinceEpoch}.jpg',
        ),
      );
      await outputFile.writeAsBytes(outputBytes, flush: true);
      if (mounted) Navigator.pop(context, outputFile);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not apply filter: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit page'),
        actions: [
          TextButton(
            onPressed: _isSaving
                ? null
                : () => _selectFilter(ScanImageFilter.original),
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: _isLoading || _isPreviewLoading || _isSaving
                ? null
                : _applyFilter,
            child: const Text('Apply'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_previewBytes != null)
                        InteractiveViewer(
                          minScale: 0.75,
                          maxScale: 4,
                          child:
                              Image.memory(_previewBytes!, fit: BoxFit.contain),
                        ),
                      if (_isPreviewLoading || _isSaving)
                        const ColoredBox(
                          color: Color(0x66000000),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: ScanImageFilter.values
                          .map(
                            (filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(filter.label),
                                selected: _selectedFilter == filter,
                                onSelected: _isSaving
                                    ? null
                                    : (_) => _selectFilter(filter),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilterRequest {
  final Uint8List sourceBytes;
  final ScanImageFilter filter;
  final int? maxWidth;

  const _FilterRequest({
    required this.sourceBytes,
    required this.filter,
    this.maxWidth,
  });
}

@pragma('vm:entry-point')
Uint8List _renderFilter(_FilterRequest request) {
  final decoded = img.decodeImage(request.sourceBytes);
  if (decoded == null) throw StateError('Unsupported image format');

  final source = request.maxWidth != null && decoded.width > request.maxWidth!
      ? img.copyResize(decoded, width: request.maxWidth)
      : decoded;
  final result = source.clone();

  switch (request.filter) {
    case ScanImageFilter.original:
      break;
    case ScanImageFilter.auto:
      img.adjustColor(result, contrast: 1.12, saturation: 1.04, gamma: 0.96);
      break;
    case ScanImageFilter.grayscale:
      img.grayscale(result);
      break;
    case ScanImageFilter.blackAndWhite:
      img.grayscale(result);
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final pixel = result.getPixel(x, y);
          final luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
          final value = luminance >= 150 ? 255 : 0;
          result.setPixelRgba(x, y, value, value, value, 255);
        }
      }
      break;
    case ScanImageFilter.sharpen:
      return Uint8List.fromList(
        img.encodeJpg(
          img.convolution(
            result,
            filter: const <num>[0, -1, 0, -1, 5, -1, 0, -1, 0],
            div: 1,
            offset: 0,
          ),
          quality: 95,
        ),
      );
  }

  return Uint8List.fromList(img.encodeJpg(result, quality: 95));
}
