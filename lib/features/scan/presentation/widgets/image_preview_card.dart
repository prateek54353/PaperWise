import 'dart:io';
import 'package:flutter/material.dart';

class ImagePreviewCard extends StatefulWidget {
  final File image;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onCrop;
  final VoidCallback onEdit;

  const ImagePreviewCard({
    super.key,
    required this.image,
    required this.index,
    required this.onDelete,
    required this.onTap,
    required this.onCrop,
    required this.onEdit,
  });

  @override
  State<ImagePreviewCard> createState() => _ImagePreviewCardState();
}

class _ImagePreviewCardState extends State<ImagePreviewCard> {
  bool _isDeleting = false;

  Future<void> _animateDelete() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted) widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Image preview card for page ${widget.index + 1}',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) => FadeTransition(
          opacity: AlwaysStoppedAnimation(progress),
          child: AnimatedScale(
            scale: _isDeleting ? 0.88 : 0.96 + 0.04 * progress,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInCubic,
            child: AnimatedOpacity(
              opacity: _isDeleting ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeIn,
              child: child,
            ),
          ),
        ),
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: GridTile(
            header: GridTileBar(
              backgroundColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              title: Text(
                'Page ${widget.index + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                semanticsLabel: 'Page number: ${widget.index + 1}',
              ),
            ),
            footer: GridTileBar(
              backgroundColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIconButton(
                    icon: Icons.tune_outlined,
                    onPressed: widget.onEdit,
                    tooltip: 'Apply filter',
                    semanticsLabel: 'Apply image filter',
                    color: colorScheme.secondary,
                  ),
                  _buildIconButton(
                    icon: Icons.crop_outlined,
                    onPressed: widget.onCrop,
                    tooltip: 'Crop Image',
                    semanticsLabel: 'Crop image',
                    color: colorScheme.primary,
                  ),
                  _buildIconButton(
                    icon: Icons.delete_outline,
                    onPressed: _animateDelete,
                    tooltip: 'Delete Image',
                    semanticsLabel: 'Delete image',
                    color: colorScheme.error,
                  ),
                ],
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              child: LayoutBuilder(
                builder: (context, constraints) => Image.file(
                  widget.image,
                  fit: BoxFit.cover,
                  cacheWidth: (constraints.maxWidth *
                          MediaQuery.of(context).devicePixelRatio)
                      .round(),
                  semanticLabel: 'Image ${widget.index + 1} for PDF',
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to create compact icon buttons
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    String? semanticsLabel,
    Color? color,
  }) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 20.0,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, color: color),
        onPressed: _isDeleting ? null : onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
