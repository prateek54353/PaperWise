import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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
      setState(() {});
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
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
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined),
            onPressed: _switchCamera,
          ),
          IconButton(
            icon: Icon(_autoCapture ? Icons.motion_photos_auto : Icons.motion_photos_off),
            tooltip: 'Auto-Capture',
            onPressed: _toggleAuto,
          ),
          TextButton(
            onPressed: _capturedFiles.isEmpty ? null : _finish,
            child: const Text('Done'),
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton.large(
                          onPressed: _capture,
                          child: const Icon(Icons.camera),
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
}

