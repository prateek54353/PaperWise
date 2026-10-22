import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:paperwise_pdf_maker/core/widgets/common_widgets.dart';

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
  bool _isShowingOriginal = false;
  int _requestId = 0;
  
  // Fine-tuning controls
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  bool _showFineTuning = false;

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

    if (_selectedFilter == ScanImageFilter.original &&
        _brightness == 0.0 &&
        _contrast == 1.0 &&
        _saturation == 1.0) {
      Navigator.pop(context, widget.imageFile);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final outputBytes = await compute(
        _renderFilterWithFineTuning,
        _FilterWithFineTuningRequest(
          sourceBytes: sourceBytes,
          filter: _selectedFilter,
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit page'),
        actions: [
          IconButton(
            icon: Icon(_showFineTuning ? Icons.tune : Icons.tune_outlined),
            tooltip: 'Fine-tune',
            onPressed: () => setState(() => _showFineTuning = !_showFineTuning),
          ),
          TextButton(
            onPressed: _isSaving
                ? null
                : () => _resetFineTuning(),
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
          ? const AppLoadingIndicator(message: 'Loading image...')
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_previewBytes != null &&
                          _sourceBytes != null &&
                          _selectedFilter != ScanImageFilter.original)
                        InteractiveViewer(
                          minScale: 0.75,
                          maxScale: 4,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 140),
                            child: Image.memory(
                              _isShowingOriginal
                                  ? _sourceBytes!
                                  : _previewBytes!,
                              key: ValueKey(_isShowingOriginal),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      if (_previewBytes != null &&
                          _sourceBytes != null &&
                          _selectedFilter != ScanImageFilter.original)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: GestureDetector(
                            onLongPressStart: (_) =>
                                setState(() => _isShowingOriginal = true),
                            onLongPressEnd: (_) =>
                                setState(() => _isShowingOriginal = false),
                            onLongPressCancel: () =>
                                setState(() => _isShowingOriginal = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isShowingOriginal
                                        ? Icons.visibility_outlined
                                        : Icons.compare_arrows,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isShowingOriginal
                                        ? 'Original'
                                        : 'Hold to compare',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_isPreviewLoading || _isSaving)
                        ColoredBox(
                          color: Colors.black.withValues(alpha: 0.4),
                          child: AppLoadingIndicator(
                            message: _isSaving ? 'Applying filter...' : 'Updating preview...',
                          ),
                        ),
                    ],
                  ),
                ),
                if (_showFineTuning) _buildFineTuningControls(colorScheme),
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

  Widget _buildFineTuningControls(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fine-tune',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            label: 'Brightness',
            value: _brightness,
            min: -100,
            max: 100,
            onChanged: (value) {
              setState(() => _brightness = value);
              _updatePreviewWithFineTuning();
            },
          ),
          const SizedBox(height: 16),
          _buildSlider(
            label: 'Contrast',
            value: _contrast,
            min: 0.5,
            max: 2.0,
            onChanged: (value) {
              setState(() => _contrast = value);
              _updatePreviewWithFineTuning();
            },
          ),
          const SizedBox(height: 16),
          _buildSlider(
            label: 'Saturation',
            value: _saturation,
            min: 0.0,
            max: 2.0,
            onChanged: (value) {
              setState(() => _saturation = value);
              _updatePreviewWithFineTuning();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value.toStringAsFixed(1),
              semanticsLabel: '$label value: ${value.toStringAsFixed(1)}',
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 200,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
          semanticFormatterCallback: (value) => '$label: ${value.toStringAsFixed(1)}',
        ),
      ],
    );
  }

  void _resetFineTuning() {
    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _saturation = 1.0;
    });
    _selectFilter(ScanImageFilter.original);
  }

  Future<void> _updatePreviewWithFineTuning() async {
    final sourceBytes = _sourceBytes;
    if (sourceBytes == null || _isPreviewLoading) return;

    final requestId = ++_requestId;
    if (mounted) {
      setState(() {
        _isPreviewLoading = true;
      });
    }

    try {
      final preview = await compute(
        _renderFilterWithFineTuning,
        _FilterWithFineTuningRequest(
          sourceBytes: sourceBytes,
          filter: _selectedFilter,
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
          maxWidth: _previewMaxWidth,
        ),
      );
      if (!mounted || requestId != _requestId) return;
      setState(() => _previewBytes = preview);
    } catch (error) {
      if (mounted && requestId == _requestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update preview: $error')),
        );
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isPreviewLoading = false);
      }
    }
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

class _FilterWithFineTuningRequest {
  final Uint8List sourceBytes;
  final ScanImageFilter filter;
  final double brightness;
  final double contrast;
  final double saturation;
  final int? maxWidth;

  const _FilterWithFineTuningRequest({
    required this.sourceBytes,
    required this.filter,
    required this.brightness,
    required this.contrast,
    required this.saturation,
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

@pragma('vm:entry-point')
Uint8List _renderFilterWithFineTuning(_FilterWithFineTuningRequest request) {
  final decoded = img.decodeImage(request.sourceBytes);
  if (decoded == null) throw StateError('Unsupported image format');

  final source = request.maxWidth != null && decoded.width > request.maxWidth!
      ? img.copyResize(decoded, width: request.maxWidth)
      : decoded;
  final result = source.clone();

  // Apply fine-tuning adjustments
  img.adjustColor(
    result,
    brightness: request.brightness,
    contrast: request.contrast,
    saturation: request.saturation,
  );

  // Apply filter
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
