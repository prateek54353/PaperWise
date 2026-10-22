import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paperwise_pdf_maker/core/widgets/common_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isBusy = false;
  final List<File> _capturedFiles = [];
  bool _flashOn = false;
  int _cameraIndex = 0;
  bool _autoCapture = false;
  bool _showGuides = true;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }
      _cameraIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      if (_cameraIndex < 0) _cameraIndex = 0;
      final camera = _cameras[_cameraIndex];
      _controller = CameraController(camera, ResolutionPreset.max, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final mode = _flashOn ? FlashMode.off : FlashMode.torch;
      await _controller!.setFlashMode(mode);
      setState(() => _flashOn = !_flashOn);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _isInitialized = false;
    });
    _controller?.dispose();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(camera, ResolutionPreset.max, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final XFile xfile = await _controller!.takePicture();
      final dir = await getTemporaryDirectory();
      final target = File(p.join(dir.path, 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg'));
      await File(xfile.path).copy(target.path);
      _capturedFiles.add(target);
      HapticFeedback.lightImpact();
      setState(() {});
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _undoCapture() {
    if (_capturedFiles.isEmpty) return;
    setState(() {
      _capturedFiles.removeLast();
    });
    HapticFeedback.mediumImpact();
  }

  void _finish() {
    Navigator.pop(context, _capturedFiles);
  }

  void _toggleAuto() {
    setState(() => _autoCapture = !_autoCapture);
    _autoTimer?.cancel();
    if (_autoCapture) {
      _autoTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (mounted && !_isBusy) {
          await _capture();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan with Camera'),
        actions: [
          Semantics(
            button: true,
            label: _flashOn ? 'Turn flash off' : 'Turn flash on',
            child: IconButton(
              icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
              tooltip: _flashOn ? 'Flash On' : 'Flash Off',
              onPressed: _toggleFlash,
            ),
          ),
          Semantics(
            button: true,
            label: 'Switch camera',
            child: IconButton(
              icon: const Icon(Icons.cameraswitch_outlined),
              tooltip: 'Switch Camera',
              onPressed: _switchCamera,
            ),
          ),
          Semantics(
            button: true,
            label: _showGuides ? 'Hide document guides' : 'Show document guides',
            child: IconButton(
              icon: Icon(_showGuides ? Icons.crop_free : Icons.crop_free_outlined),
              tooltip: 'Toggle Guides',
              onPressed: () => setState(() => _showGuides = !_showGuides),
            ),
          ),
          Semantics(
            button: true,
            label: _autoCapture ? 'Disable auto capture' : 'Enable auto capture',
            child: IconButton(
              icon: Icon(_autoCapture ? Icons.motion_photos_auto : Icons.motion_photos_off),
              tooltip: 'Auto-Capture',
              onPressed: _toggleAuto,
            ),
          ),
          Semantics(
            button: true,
            label: _capturedFiles.isEmpty ? 'No images captured, button disabled' : 'Finish scanning',
            enabled: _capturedFiles.isNotEmpty,
            child: TextButton(
              onPressed: _capturedFiles.isEmpty ? null : _finish,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
      body: !_isInitialized
          ? const AppLoadingIndicator(message: 'Initializing camera...')
          : Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                if (_showGuides) _buildDocumentGuides(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_capturedFiles.isNotEmpty)
                          Semantics(
                            button: true,
                            label: 'Undo last capture',
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: FloatingActionButton.small(
                                heroTag: 'undo-capture',
                                tooltip: 'Undo Last Capture',
                                onPressed: _undoCapture,
                                child: const Icon(Icons.undo),
                              ),
                            ),
                          ),
                        Semantics(
                          button: true,
                          label: 'Capture photo',
                          child: FloatingActionButton.large(
                            tooltip: 'Capture Photo',
                            onPressed: _capture,
                            child: const Icon(Icons.camera),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_capturedFiles.isNotEmpty)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: SizedBox(
                      width: 72,
                      height: 96,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_capturedFiles.last, fit: BoxFit.cover),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDocumentGuides() {
    return IgnorePointer(
      child: Container(
        color: Colors.transparent,
        child: CustomPaint(
          size: Size.infinite,
          painter: _DocumentGuidePainter(),
        ),
      ),
    );
  }
}

class _DocumentGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final cornerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final margin = 40.0;
    final cornerLength = 60.0;

    // Draw document frame (rectangle with corners)
    final rect = Rect.fromLTWH(
      margin,
      margin,
      size.width - (margin * 2),
      size.height - (margin * 2),
    );

    // Draw corner guides
    // Top-left
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.top + cornerLength),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - cornerLength),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );

    // Draw center crosshair
    final center = rect.center;
    final crosshairSize = 20.0;
    canvas.drawLine(
      Offset(center.dx - crosshairSize, center.dy),
      Offset(center.dx + crosshairSize, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairSize),
      Offset(center.dx, center.dy + crosshairSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

