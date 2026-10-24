import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/core/constants/app_constants.dart';
import 'package:paperwise_pdf_maker/core/theme/app_tokens.dart';

class PaperWiseBrandMark extends StatelessWidget {
  const PaperWiseBrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: AppConstants.appName,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        child: Icon(
          Icons.description_rounded,
          color: scheme.onPrimary,
          size: size * 0.58,
        ),
      ),
    );
  }
}

class PaperWiseAppBarTitle extends StatelessWidget {
  const PaperWiseAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const PaperWiseBrandMark(),
        const SizedBox(width: AppTokens.space12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConstants.appName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                AppConstants.appTagline,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}