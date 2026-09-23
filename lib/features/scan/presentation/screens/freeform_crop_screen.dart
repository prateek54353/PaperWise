import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FreeformCropScreen extends StatefulWidget {
  final File imageFile;
  const FreeformCropScreen({super.key, required this.imageFile});
  @override
  State<FreeformCropScreen> createState() => _FreeformCropScreenState();
}

class _FreeformCropScreenState extends State<FreeformCropScreen> {
  Uint8List? _original, _preview;
  int _width = 1, _height = 1, _turns = 0;
  bool _busy = true, _saving = false;
  double _zoom = 1;
  Offset _pan = Offset.zero, _last = Offset.zero;
  double _startZoom = 1;
  int? _corner;
  List<Offset> _points = _defaults();

  static List<Offset> _defaults() => [
    const Offset(.06, .06), const Offset(.94, .06),
    const Offset(.94, .94), const Offset(.06, .94),
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final decoded = await compute(_makePreview, bytes);
      if (!mounted) return;
      setState(() {
        _original = bytes; _preview = decoded.bytes;
        _width = decoded.width; _height = decoded.height;
        _points = _defaults(); _turns = 0; _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open image: $e')));
      Navigator.pop(context);
    }
  }

  Size _fit(Size max) {
    final r = _width / _height;
    var w = max.width, h = w / r;
    if (h > max.height) { h = max.height; w = h * r; }
    return Size(w, h);
  }

  Offset _imagePoint(Offset p, Rect r) => Offset(
    ((p.dx - r.left - _pan.dx) / (_zoom * r.width)).clamp(0.0, 1.0).toDouble(),
    ((p.dy - r.top - _pan.dy) / (_zoom * r.height)).clamp(0.0, 1.0).toDouble(),
  );

  void _start(ScaleStartDetails d, Rect r) {
    _last = d.localFocalPoint;
    _startZoom = _zoom;
    final p = _imagePoint(_last, r);
    _corner = null;
    // Use a larger threshold for better corner detection
    var best = 0.2;
    for (var i = 0; i < 4; i++) {
      final distance = (_points[i] - p).distance;
      if (distance < best) { best = distance; _corner = i; }
    }
  }

  void _update(ScaleUpdateDetails d, Rect r) {
    if (_corner != null) {
      setState(() => _points[_corner!] = _imagePoint(d.localFocalPoint, r));
    } else {
      setState(() {
        _zoom = (_startZoom * d.scale).clamp(1.0, 5.0).toDouble();
        _pan += d.localFocalPoint - _last;
        _last = d.localFocalPoint;
      });
    }
  }

  Future<void> _rotate() async {
    if (_original == null || _busy) return;
    setState(() => _busy = true);
    try {
      final turns = (_turns + 1) % 4;
      final p = await compute(_previewRotated, _Rotation(_original!, turns));
      if (!mounted) return;
      setState(() {
        _turns = turns; _preview = p.bytes; _width = p.width; _height = p.height;
        _points = _points.map((v) => Offset(1 - v.dy, v.dx)).toList();
        _zoom = 1; _pan = Offset.zero; _busy = false;
      });
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not rotate image: $e')));
    }
  }

  Future<void> _reset() async {
    setState(() { _busy = true; _points = _defaults(); _zoom = 1; _pan = Offset.zero; });
    await _load();
  }

  Future<void> _apply() async {
    if (_original == null || _saving || _busy) return;
    setState(() => _saving = true);
    try {
      final bytes = await compute(_warp, _Crop(_original!, _points.map((p) => [p.dx, p.dy]).toList(), _turns));
      final dir = await getTemporaryDirectory();
      final output = File(path.join(dir.path, 'paperwise_crop_${DateTime.now().microsecondsSinceEpoch}.jpg'));
      await output.writeAsBytes(bytes, flush: true);
      if (mounted) Navigator.pop(context, output);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not crop image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : colors.surface,
      appBar: AppBar(
        title: const Text('Freeform crop'),
        leading: IconButton(tooltip: 'Cancel', onPressed: _saving ? null : () => Navigator.pop(context), icon: const Icon(Icons.close)),
        actions: [
          TextButton(onPressed: _busy || _saving ? null : _reset, child: const Text('Reset')),
          TextButton(onPressed: _busy || _saving ? null : _apply, child: const Text('Apply')),
        ],
      ),
      body: _busy || _preview == null ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(builder: (context, box) {
          final size = _fit(Size(box.maxWidth, box.maxHeight));
          final rect = Rect.fromCenter(center: Offset(box.maxWidth / 2, box.maxHeight / 2), width: size.width, height: size.height);
          return Stack(children: [
            Positioned.fill(child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (d) => _start(d, rect),
              onScaleUpdate: (d) => _update(d, rect),
              onScaleEnd: (d) {
                _corner = null;
              },
              child: Stack(children: [
                Positioned(left: rect.left + _pan.dx, top: rect.top + _pan.dy, width: rect.width * _zoom, height: rect.height * _zoom,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.memory(_preview!, fit: BoxFit.fill),
                    CustomPaint(painter: _Overlay(_points)),
                  ])),
                Positioned(left: 16, right: 16, bottom: 14,
                  child: Text('Drag corners · Pinch to zoom · Drag to move', textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant))),
              ]),
            )),
            Positioned(left: 20, bottom: 48, child: FloatingActionButton.small(
              heroTag: 'freeform-rotate', tooltip: 'Rotate 90°',
              onPressed: _busy || _saving ? null : _rotate,
              child: const Icon(Icons.rotate_90_degrees_ccw))),
            if (_saving) const Positioned.fill(child: ColoredBox(color: Color(0x99000000), child: Center(child: CircularProgressIndicator()))),
          ]);
        }),
    );
  }
}

class _Overlay extends CustomPainter {
  final List<Offset> points;
  const _Overlay(this.points);
  @override
  void paint(Canvas c, Size s) {
    final p = points.map((v) => Offset(v.dx * s.width, v.dy * s.height)).toList();
    final shape = Path()..moveTo(p[0].dx, p[0].dy);
    for (final v in p.skip(1)) { shape.lineTo(v.dx, v.dy); }
    shape.close();
    final shade = Path()..fillType = PathFillType.evenOdd..addRect(Offset.zero & s)..addPath(shape, Offset.zero);
    c.drawPath(shade, Paint()..color = Colors.black.withValues(alpha: .52));
    c.drawPath(shape, Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke);
    final grid = Paint()..color = Colors.white.withValues(alpha: .45)..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final t = i / 3;
      c.drawLine(Offset.lerp(p[0], p[1], t)!, Offset.lerp(p[3], p[2], t)!, grid);
      c.drawLine(Offset.lerp(p[0], p[3], t)!, Offset.lerp(p[1], p[2], t)!, grid);
    }
    for (final v in p) {
      c.drawCircle(v, 10, Paint()..color = Colors.black.withValues(alpha: .7));
      c.drawCircle(v, 7, Paint()..color = Colors.white);
      c.drawCircle(v, 4, Paint()..color = const Color(0xFF64DD9A));
    }
  }
  @override
  bool shouldRepaint(covariant _Overlay old) => old.points != points;
}

class _Preview {
  final Uint8List bytes; final int width, height;
  const _Preview(this.bytes, this.width, this.height);
}

@pragma('vm:entry-point')
_Preview _makePreview(Uint8List bytes) {
  final image = img.bakeOrientation(img.decodeImage(bytes)!);
  final small = image.width > 1800 ? img.copyResize(image, width: 1800) : image;
  return _Preview(Uint8List.fromList(img.encodeJpg(small, quality: 88)), image.width, image.height);
}

class _Rotation {
  final Uint8List bytes; final int turns;
  const _Rotation(this.bytes, this.turns);
}
@pragma('vm:entry-point')
_Preview _previewRotated(_Rotation r) {
  final image = img.copyRotate(img.bakeOrientation(img.decodeImage(r.bytes)!), angle: r.turns * 90);
  final small = image.width > 1800 ? img.copyResize(image, width: 1800) : image;
  return _Preview(Uint8List.fromList(img.encodeJpg(small, quality: 88)), image.width, image.height);
}

class _Crop {
  final Uint8List bytes; final List<List<double>> points; final int turns;
  const _Crop(this.bytes, this.points, this.turns);
}

@pragma('vm:entry-point')
Uint8List _warp(_Crop crop) {
  var src = img.bakeOrientation(img.decodeImage(crop.bytes)!);
  if (crop.turns > 0) src = img.copyRotate(src, angle: crop.turns * 90);
  final q = crop.points.map((v) => Offset(v[0], v[1])).toList();
  final corners = q.map((p) => Offset(p.dx * src.width, p.dy * src.height)).toList();
  int dist(int a, int b) => (corners[a] - corners[b]).distance.round();
  final w = ((dist(0, 1) + dist(3, 2)) / 2).round().clamp(1, src.width * 2).toInt();
  final h = ((dist(0, 3) + dist(1, 2)) / 2).round().clamp(1, src.height * 2).toInt();
  final hmat = _solve(q);
  final out = img.Image(width: w, height: h, numChannels: 3);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final u = x / (w - 1 == 0 ? 1 : w - 1), v = y / (h - 1 == 0 ? 1 : h - 1);
      final den = hmat[6] * u + hmat[7] * v + 1;
      final sx = ((hmat[0] * u + hmat[1] * v + hmat[2]) / den * (src.width - 1)).round().clamp(0, src.width - 1).toInt();
      final sy = ((hmat[3] * u + hmat[4] * v + hmat[5]) / den * (src.height - 1)).round().clamp(0, src.height - 1).toInt();
      final px = src.getPixel(sx, sy);
      out.setPixelRgba(x, y, px.r, px.g, px.b, 255);
    }
  }
  return Uint8List.fromList(img.encodeJpg(out, quality: 96));
}

List<double> _solve(List<Offset> src) {
  const dst = [Offset(0,0), Offset(1,0), Offset(1,1), Offset(0,1)];
  final a = <List<double>>[];
  for (var i = 0; i < 4; i++) {
    final x = dst[i].dx, y = dst[i].dy, u = src[i].dx, v = src[i].dy;
    a.add([x,y,1,0,0,0,-u*x,-u*y,u]);
    a.add([0,0,0,x,y,1,-v*x,-v*y,v]);
  }
  for (var col = 0; col < 8; col++) {
    var pivot = col;
    for (var row = col + 1; row < 8; row++) { if (a[row][col].abs() > a[pivot][col].abs()) pivot = row; }
    final swap = a[col]; a[col] = a[pivot]; a[pivot] = swap;
    final divisor = a[col][col];
    if (divisor.abs() < 1e-12) throw StateError('Invalid crop shape');
    for (var j = col; j < 9; j++) { a[col][j] /= divisor; }
    for (var row = 0; row < 8; row++) {
      if (row == col) continue;
      final factor = a[row][col];
      for (var j = col; j < 9; j++) { a[row][j] -= factor * a[col][j]; }
    }
  }
  return List.generate(8, (i) => a[i][8]);
}
