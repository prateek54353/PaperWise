import 'dart:io';
import 'package:flutter/material.dart';

class ImagePreviewCard extends StatelessWidget {
  final File image;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onCrop;

  const ImagePreviewCard({
    super.key,
    required this.image,
    required this.index,
    required this.onDelete,
    required this.onTap,

    required this.onCrop,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Image preview card for page ${index + 1}',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: GridTile(
          header: GridTileBar(
            backgroundColor: colorScheme.surfaceVariant.withOpacity(0.7),
            title: Text(
              'Page ${index + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
              semanticsLabel: 'Page number: ${index + 1}',
            ),
          ),
          footer: GridTileBar(
            backgroundColor: colorScheme.surfaceVariant.withOpacity(0.7),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                _buildIconButton(
                  icon: Icons.crop_outlined,
                  onPressed: onCrop,
                  tooltip: 'Crop Image',
                  semanticsLabel: 'Crop image',
                  color: colorScheme.primary,
                ),
                _buildIconButton(
                  icon: Icons.delete_outline,
                  onPressed: onDelete,
                  tooltip: 'Delete Image',
                  semanticsLabel: 'Delete image',
                  color: colorScheme.error,
                ),
              ],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Image.file(
              image,
              fit: BoxFit.cover,
              semanticLabel: 'Image ${index + 1} for PDF',
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
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}