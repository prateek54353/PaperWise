import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperwise_pdf_maker/core/theme/app_tokens.dart';
import 'package:paperwise_pdf_maker/features/library/domain/entities/pdf_entity.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/providers/library_provider.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/pdf_merge_screen.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/pdf_split_screen.dart';
import 'package:paperwise_pdf_maker/features/scan/presentation/screens/scan_screen.dart';
import 'package:paperwise_pdf_maker/features/settings/domain/value_objects/compression_level.dart';
import 'package:paperwise_pdf_maker/features/settings/presentation/providers/settings_provider.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  Future<PdfEntity?> _pickPdf(BuildContext context, WidgetRef ref) async {
    final pdfs = ref.read(libraryProvider).pdfs;
    if (pdfs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan or import a PDF first')),
      );
      return null;
    }
    return showModalBottomSheet<PdfEntity>(
      context: context,
      builder: (context) => ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Choose a PDF',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final pdf in pdfs)
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(pdf.name),
              onTap: () => Navigator.pop(context, pdf),
            ),
        ],
      ),
    );
  }

  Future<List<PdfEntity>?> _pickPdfs(BuildContext context, WidgetRef ref) async {
    final pdfs = ref.read(libraryProvider).pdfs;
    if (pdfs.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need at least two PDFs to merge')),
      );
      return null;
    }
    final selected = <PdfEntity>{};
    return showDialog<List<PdfEntity>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select PDFs to merge'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final pdf in pdfs)
                      CheckboxListTile(
                        value: selected.contains(pdf),
                        title: Text(pdf.name),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selected.add(pdf);
                            } else {
                              selected.remove(pdf);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selected.length >= 2
                      ? () => Navigator.pop(context, selected.toList())
                      : null,
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compression =
        ref.watch(settingsProvider).settings.compressionLevel.displayName;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space16),
        children: [
          Text(
            'PDF tools',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          _ToolTile(
            icon: Icons.document_scanner_outlined,
            title: 'Scan or import',
            subtitle: 'Camera, gallery, crop, filters, and page size',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
            },
          ),
          _ToolTile(
            icon: Icons.merge_type,
            title: 'Merge PDF',
            subtitle: 'Combine two or more documents',
            onTap: () async {
              final pdfs = await _pickPdfs(context, ref);
              if (pdfs == null || !context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PdfMergeScreen(pdfs: pdfs)),
              );
            },
          ),
          _ToolTile(
            icon: Icons.call_split,
            title: 'Split PDF',
            subtitle: 'Extract pages or save each page',
            onTap: () async {
              final pdf = await _pickPdf(context, ref);
              if (pdf == null || !context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PdfSplitScreen(pdf: pdf)),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Quality',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          _ToolTile(
            icon: Icons.compress,
            title: 'Scan compression',
            subtitle: 'Current image quality: $compression',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Change compression under Settings → Image Quality. It applies when you generate a PDF from scans.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: AppTokens.borderRadiusMd,
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Icon(icon),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}