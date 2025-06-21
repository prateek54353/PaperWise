import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PdfListItem extends StatelessWidget {
  final File pdfFile;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PdfListItem({
    super.key,
    required this.pdfFile,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = pdfFile.path.split('/').last.replaceAll('.pdf', '');
    final lastModified = pdfFile.lastModifiedSync();
    final formattedDate = DateFormat.yMMMd().add_jm().format(lastModified);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red, size: 40),
        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(formattedDate),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}