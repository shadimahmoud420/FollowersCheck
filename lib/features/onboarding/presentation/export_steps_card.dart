import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Numbered list of the steps to request a JSON export.
class ExportStepsCard extends StatelessWidget {
  const ExportStepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final steps = [
      l10n.exportStep1,
      l10n.exportStep2,
      l10n.exportStep3,
      l10n.exportStep4,
      l10n.exportStep5,
      l10n.exportStep6,
    ];
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.exportStepsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        '${i + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(steps[i], style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "We never ask for your password" reassurance banner.
class NoPasswordBanner extends StatelessWidget {
  const NoPasswordBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: scheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).neverPassword,
              style: TextStyle(color: scheme.onTertiaryContainer, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
