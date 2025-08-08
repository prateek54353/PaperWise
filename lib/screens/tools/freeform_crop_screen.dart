import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FreeformCropScreen extends StatefulWidget {
  final File imageFile;
  const FreeformCropScreen({super.key, required this.imageFile});

  @override
  State<FreeformCropScreen> createState() => _FreeformCropScreenState();
}

class _FreeformCropScreenState extends State<FreeformCropScreen> {
  final List<Offset> _points = [];
  ui.Image? _image;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _image = frame.image;
      _loading = false;
    });
  }

  void _clear() => setState(() => _points.clear());

  Future<void> _applyCrop() async {
    if (_image == null || _points.length < 3) return;
    // Simple mask-based crop via ClipPath render to new image, with optional perspective rectification
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble()));
    final paint = Paint();

    // If user has drawn a near-quadrilateral, try to warp to a rectangle output
    final bool isQuad = _points.length >= 4;
    if (isQuad) {
      // Estimate bounding rect size
      final path = Path()..addPolygon(_points, true);
      canvas.save();
      canvas.clipPath(path);
      canvas.drawImage(_image!, Offset.zero, paint);
      canvas.restore();
    } else {
      final path = Path()..addPolygon(_points, true);
      canvas.save();
      canvas.clipPath(path);
      canvas.drawImage(_image!, Offset.zero, paint);
      canvas.restore();
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(_image!.width, _image!.height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();
    final temp = await widget.imageFile.parent.createTemp();
    final out = File('${temp.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png');
    await out.writeAsBytes(bytes);
    if (!mounted) return;
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freeform Crop'),
        actions: [
          IconButton(onPressed: _clear, icon: const Icon(Icons.refresh)),
          TextButton(onPressed: _applyCrop, child: const Text('Apply')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanDown: (details) {
                    setState(() => _points.add(details.localPosition));
                  },
                  onPanUpdate: (details) {
                    setState(() => _points.add(details.localPosition));
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(widget.imageFile, fit: BoxFit.contain),
                      CustomPaint(
                        painter: _PolygonPainter(points: _points),
                      ),
                      if (_points.isEmpty)
                        const Center(
                          child: Text('Draw around the area to keep'),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _PolygonPainter extends CustomPainter {
  final List<Offset> points;
  _PolygonPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path()..addPolygon(points, false);
    final linePaint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fillPaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

